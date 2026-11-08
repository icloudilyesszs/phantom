import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/library_service.dart';
import '../services/player_service.dart';
import '../widgets/track_tile.dart';

/// Contenu d'une playlist.
class PlaylistScreen extends StatelessWidget {
  final String name;
  const PlaylistScreen({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    final lib = context.watch<LibraryService>();
    final tracks = lib.playlists[name] ?? [];
    final player = context.read<PlayerService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Supprimer la playlist',
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('Supprimer "$name" ?'),
                  content: const Text('Les sons ne seront pas supprimés.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Annuler')),
                    FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Supprimer')),
                  ],
                ),
              );
              if (ok == true) {
                await lib.deletePlaylist(name);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      floatingActionButton: tracks.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: () => player.playList(tracks, 0),
              child: const Icon(Icons.play_arrow),
            ),
      body: tracks.isEmpty
          ? const Center(
              child: Text('Playlist vide.\nAjoute des sons avec le menu ⋮',
                  textAlign: TextAlign.center))
          : ListView.builder(
              itemCount: tracks.length,
              itemBuilder: (_, i) =>
                  TrackTile(list: tracks, index: i, playlistName: name),
            ),
    );
  }
}
