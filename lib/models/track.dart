/// Un morceau, peu importe d'où il vient (Audius, fichier local, source perso).
class Track {
  final String id;
  final String title;
  final String artist;
  final String? artworkUrl;
  final int? durationSeconds;
  final String sourceId;
  final String? localPath;

  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.sourceId,
    this.artworkUrl,
    this.durationSeconds,
    this.localPath,
  });

  /// Identifiant unique, toutes sources confondues.
  String get key => '$sourceId:$id';

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'artworkUrl': artworkUrl,
        'durationSeconds': durationSeconds,
        'sourceId': sourceId,
        'localPath': localPath,
      };

  factory Track.fromJson(Map<String, dynamic> json) => Track(
        id: json['id'].toString(),
        title: (json['title'] ?? 'Sans titre').toString(),
        artist: (json['artist'] ?? 'Inconnu').toString(),
        artworkUrl: json['artworkUrl'] as String?,
        durationSeconds: json['durationSeconds'] as int?,
        sourceId: (json['sourceId'] ?? 'local').toString(),
        localPath: json['localPath'] as String?,
      );

  @override
  bool operator ==(Object other) => other is Track && other.key == key;

  @override
  int get hashCode => key.hashCode;
}
