import 'package:flutter/material.dart';

import '../models/track.dart';

/// Pochette d'un morceau (ou une icône si pas d'image).
class Artwork extends StatelessWidget {
  final Track? track;
  final double size;
  final double radius;

  const Artwork({super.key, this.track, this.size = 48, this.radius = 8});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = Container(
      width: size,
      height: size,
      color: scheme.primaryContainer,
      child: Icon(
        track?.localPath != null ? Icons.audio_file : Icons.music_note,
        size: size * 0.45,
        color: scheme.onPrimaryContainer,
      ),
    );
    final url = track?.artworkUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: url == null
          ? placeholder
          : Image.network(
              url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => placeholder,
            ),
    );
  }
}
