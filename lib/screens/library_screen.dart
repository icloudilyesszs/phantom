import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/library_service.dart';
import '../services/player_service.dart';
import '../widgets/track_tile.dart';
import 'playlist_screen.dart';

/// Bibliothèque : fichiers importés, playlists, J'aime.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bibliothèque'),
          bottom: const TabBar(tabs: [
            Tab(text: 'Playlists'),
            Tab(text: 'J\'aime'),
            Tab(text: 'Mes fichiers'),
          ]),
        ),
        body: const TabBarView(children: [
          _PlaylistsTab(),
          _LikedTab(),
          _FilesTab(),
        ]),
      ),
    );
  }
}

class _PlaylistsTab extends StatelessWidget {
  const _PlaylistsTab();

  @override
  Widget build(BuildContext context) {
    final lib = context.watch<LibraryService>();
    final names = lib.playlists.keys.toList();
    return ListView(
      children: [
        ListTile(
          leading: const CircleAvatar(child: Icon(Icons.add)),
          title: const Text('Nouvelle playlist'),
          onTap: () async {
            final name = await askPlaylistName(context);
            if (name != null) await lib.createPlaylist(name);
          },
        ),
        for (final n in names)
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.queue_music)),
            title: Text(n),
            subtitle: Text('${lib.playlists[n]!.length} titres'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => PlaylistScreen(name: n)),
            ),
          ),
      ],
    );
  }
}

class _LikedTab extends StatelessWidget {
  const _LikedTab();

  @override
  Widget build(BuildContext context) {
    final liked = context.watch<LibraryService>().liked;
    if (liked.isEmpty) {
      return const Center(child: Text('Aucun titre aimé pour l\'instant'));
    }
    return ListView.builder(
      itemCount: liked.length,
      itemBuilder: (_, i) => TrackTile(list: liked, index: i),
    );
  }
}

class _FilesTab extends StatelessWidget {
  const _FilesTab();

  @override
  Widget build(BuildContext context) {
    final lib = context.watch<LibraryService>();
    final files = lib.localTracks;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Importer des sons'),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      final n = await lib.importLocal();
                      messenger.showSnackBar(
                          SnackBar(content: Text('$n son(s) ajouté(s)')));
                    } catch (_) {
                      messenger.showSnackBar(const SnackBar(
                          content: Text('Import impossible')));
                    }
                  },
                ),
              ),
              if (files.isNotEmpty) ...[
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () =>
                      context.read<PlayerService>().playList(files, 0),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: files.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Ajoute tes mp3, m4a, flac ou wav.\n'
                      'Astuce : nomme-les "Artiste - Titre".',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: files.length,
                  itemBuilder: (_, i) => TrackTile(list: files, index: i),
                ),
        ),
      ],
    );
  }
}
