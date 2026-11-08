import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/library_service.dart';
import '../services/player_service.dart';
import '../widgets/artwork.dart';
import '../widgets/track_tile.dart';

/// Écran "en cours de lecture" en grand.
class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerService>();
    final lib = context.watch<LibraryService>();
    final track = player.current;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('En cours'),
        centerTitle: true,
        actions: [
          if (track != null)
            IconButton(
              icon: const Icon(Icons.playlist_add),
              tooltip: 'Ajouter à une playlist',
              onPressed: () => showAddToPlaylist(context, track),
            ),
        ],
      ),
      body: track == null
          ? const Center(child: Text('Rien en lecture'))
          : SafeArea(
              child: LayoutBuilder(builder: (context, c) {
                final art = (c.maxWidth - 64).clamp(160.0, 420.0).toDouble();
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Artwork(track: track, size: art, radius: 20),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(track.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(track.artist,
                                    style: TextStyle(
                                        color: scheme.onSurfaceVariant,
                                        fontSize: 16)),
                              ],
                            ),
                          ),
                          IconButton(
                            iconSize: 30,
                            icon: Icon(
                              lib.isLiked(track)
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: lib.isLiked(track) ? scheme.primary : null,
                            ),
                            onPressed: () => lib.toggleLike(track),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const _SeekBar(),
                      if (player.error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(player.error!,
                              style: TextStyle(color: scheme.error)),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(Icons.shuffle,
                                color: player.shuffle ? scheme.primary : null),
                            onPressed: player.toggleShuffle,
                          ),
                          IconButton(
                            iconSize: 40,
                            icon: const Icon(Icons.skip_previous),
                            onPressed: player.previous,
                          ),
                          player.loading
                              ? const SizedBox(
                                  width: 72,
                                  height: 72,
                                  child: Padding(
                                    padding: EdgeInsets.all(18),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : IconButton.filled(
                                  iconSize: 48,
                                  icon: Icon(player.isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow),
                                  onPressed: player.toggle,
                                ),
                          IconButton(
                            iconSize: 40,
                            icon: const Icon(Icons.skip_next),
                            onPressed: player.next,
                          ),
                          IconButton(
                            icon: Icon(Icons.repeat_one,
                                color:
                                    player.repeatOne ? scheme.primary : null),
                            onPressed: player.toggleRepeat,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              }),
            ),
    );
  }
}

class _SeekBar extends StatefulWidget {
  const _SeekBar();

  @override
  State<_SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<_SeekBar> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final player = context.read<PlayerService>();
    return StreamBuilder<Duration>(
      stream: player.player.positionStream,
      builder: (context, snap) {
        final dur = player.player.duration ?? Duration.zero;
        final pos = snap.data ?? Duration.zero;
        final max = dur.inMilliseconds.toDouble();
        final value =
            (_dragValue ?? pos.inMilliseconds.toDouble()).clamp(0.0, max > 0 ? max : 1.0).toDouble();
        return Column(
          children: [
            Slider(
              value: value,
              max: max > 0 ? max : 1.0,
              onChanged: max > 0 ? (v) => setState(() => _dragValue = v) : null,
              onChangeEnd: (v) {
                player.seek(Duration(milliseconds: v.round()));
                setState(() => _dragValue = null);
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(formatDuration(Duration(milliseconds: value.round()))),
                  Text(formatDuration(dur)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
