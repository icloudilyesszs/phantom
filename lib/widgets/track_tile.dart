import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/track.dart';
import '../services/library_service.dart';
import '../services/player_service.dart';
import 'artwork.dart';

String formatDuration(Duration d) {
  final m = d.inMinutes;
  final s = d.inSeconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

/// Une ligne de morceau dans une liste. Toucher = lire la liste à partir d'ici.
class TrackTile extends StatelessWidget {
  final List<Track> list;
  final int index;
  final String? playlistName;

  const TrackTile({
    super.key,
    required this.list,
    required this.index,
    this.playlistName,
  });

  @override
  Widget build(BuildContext context) {
    final track = list[index];
    final player = context.watch<PlayerService>();
    final isCurrent = player.current == track;
    final scheme = Theme.of(context).colorScheme;
    final secs = track.durationSeconds;

    return ListTile(
      leading: Artwork(track: track),
      title: Text(
        track.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isCurrent ? scheme.primary : null,
          fontWeight: isCurrent ? FontWeight.bold : null,
        ),
      ),
      subtitle: Text(
        secs != null
            ? '${track.artist} · ${formatDuration(Duration(seconds: secs))}'
            : track.artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => context.read<PlayerService>().playList(list, index),
      trailing: _TrackMenu(track: track, playlistName: playlistName),
    );
  }
}

class _TrackMenu extends StatelessWidget {
  final Track track;
  final String? playlistName;

  const _TrackMenu({required this.track, this.playlistName});

  @override
  Widget build(BuildContext context) {
    final lib = context.watch<LibraryService>();
    final liked = lib.isLiked(track);
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) async {
        final library = context.read<LibraryService>();
        switch (value) {
          case 'like':
            await library.toggleLike(track);
            break;
          case 'playlist':
            await showAddToPlaylist(context, track);
            break;
          case 'remove_playlist':
            if (playlistName != null) {
              await library.removeFromPlaylist(playlistName!, track);
            }
            break;
          case 'delete':
            await library.removeLocal(track);
            break;
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'like',
          child: Text(liked ? 'Retirer des J\'aime' : 'J\'aime'),
        ),
        const PopupMenuItem(
          value: 'playlist',
          child: Text('Ajouter à une playlist'),
        ),
        if (playlistName != null)
          const PopupMenuItem(
            value: 'remove_playlist',
            child: Text('Retirer de cette playlist'),
          ),
        if (track.localPath != null && playlistName == null)
          const PopupMenuItem(
            value: 'delete',
            child: Text('Supprimer le fichier'),
          ),
      ],
    );
  }
}

/// Fenêtre pour choisir (ou créer) une playlist.
Future<void> showAddToPlaylist(BuildContext context, Track track) async {
  final library = context.read<LibraryService>();
  final messenger = ScaffoldMessenger.of(context);
  final chosen = await showModalBottomSheet<String>(
    context: context,
    builder: (ctx) {
      final names = library.playlists.keys.toList();
      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Nouvelle playlist'),
              onTap: () async {
                final name = await askPlaylistName(ctx);
                if (name != null && ctx.mounted) Navigator.pop(ctx, name);
              },
            ),
            for (final n in names)
              ListTile(
                leading: const Icon(Icons.queue_music),
                title: Text(n),
                onTap: () => Navigator.pop(ctx, n),
              ),
          ],
        ),
      );
    },
  );
  if (chosen == null) return;
  if (!library.playlists.containsKey(chosen)) {
    await library.createPlaylist(chosen);
  }
  await library.addToPlaylist(chosen, track);
  messenger.showSnackBar(SnackBar(content: Text('Ajouté à "$chosen"')));
}

/// Petite fenêtre pour taper le nom d'une playlist.
Future<String?> askPlaylistName(BuildContext context) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Nom de la playlist'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Ex : Sons du soir'),
        onSubmitted: (v) => Navigator.pop(ctx, v.trim().isEmpty ? null : v.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () {
            final v = controller.text.trim();
            Navigator.pop(ctx, v.isEmpty ? null : v);
          },
          child: const Text('Créer'),
        ),
      ],
    ),
  );
}
