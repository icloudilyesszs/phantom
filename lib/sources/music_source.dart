import '../models/track.dart';

/// Une "source" = un endroit d'où vient la musique.
/// Pour en ajouter une : crée une classe qui implémente MusicSource,
/// puis ajoute-la dans la liste de lib/sources/sources.dart.
abstract class MusicSource {
  /// Identifiant court et unique (ex : "audius").
  String get id;

  /// Nom affiché dans l'appli.
  String get name;

  /// true si la source sait chercher des morceaux.
  bool get canSearch;

  Future<List<Track>> search(String query);

  /// Morceaux mis en avant sur l'accueil.
  Future<List<Track>> trending();

  /// Lien (ou fichier) à lire pour ce morceau.
  Future<Uri> streamUri(Track track);
}
