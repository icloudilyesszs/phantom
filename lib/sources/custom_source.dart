import '../models/track.dart';
import 'music_source.dart';

/// Case "source perso" : modèle vide à remplir de ton côté.
///
/// Pour l'activer :
/// 1. Remplis les fonctions ci-dessous.
/// 2. Dans lib/sources/sources.dart, enlève les // devant CustomSource().
class CustomSource implements MusicSource {
  @override
  String get id => 'perso';

  @override
  String get name => 'Source perso';

  @override
  bool get canSearch => true;

  @override
  Future<List<Track>> search(String query) async {
    // Renvoie une liste de Track(id:, title:, artist:, artworkUrl:, sourceId: id)
    return [];
  }

  @override
  Future<List<Track>> trending() async => [];

  @override
  Future<Uri> streamUri(Track track) async {
    // Renvoie le lien audio à lire pour ce morceau.
    throw UnimplementedError('Source perso pas encore remplie');
  }
}
