import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/track.dart';
import 'music_source.dart';

/// Tes propres fichiers audio (mp3, m4a, flac, wav, aac).
/// Les fichiers choisis sont copiés dans le dossier de l'appli.
class LocalSource implements MusicSource {
  static const extensions = ['mp3', 'm4a', 'flac', 'wav', 'aac'];

  @override
  String get id => 'local';

  @override
  String get name => 'Mes fichiers';

  @override
  bool get canSearch => false;

  @override
  Future<List<Track>> search(String query) async => [];

  @override
  Future<List<Track>> trending() async => [];

  @override
  Future<Uri> streamUri(Track track) async => Uri.file(track.localPath!);

  Future<Directory> _musicDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'Phantom', 'musique'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Ouvre le sélecteur de fichiers et renvoie les morceaux importés.
  Future<List<Track>> importFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
      allowMultiple: true,
    );
    if (result == null) return [];
    final dir = await _musicDir();
    final tracks = <Track>[];
    for (final file in result.files) {
      final path = file.path;
      if (path == null) continue;
      final name = p.basename(path);
      final target = p.join(dir.path, name);
      if (!await File(target).exists()) {
        await File(path).copy(target);
      }
      final title = p.basenameWithoutExtension(name);
      String artist = 'Mes fichiers';
      String cleanTitle = title;
      // "Artiste - Titre.mp3" -> on sépare
      final parts = title.split(' - ');
      if (parts.length >= 2) {
        artist = parts.first.trim();
        cleanTitle = parts.sublist(1).join(' - ').trim();
      }
      tracks.add(Track(
        id: name,
        title: cleanTitle,
        artist: artist,
        sourceId: id,
        localPath: target,
      ));
    }
    return tracks;
  }

  Future<void> deleteFile(Track track) async {
    final path = track.localPath;
    if (path == null) return;
    final f = File(path);
    if (await f.exists()) await f.delete();
  }
}
