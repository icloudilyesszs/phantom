import 'audius_source.dart';
import 'local_source.dart';
import 'music_source.dart';
import 'custom_source.dart';

/// Toutes les sources de musique de Phantom.
class Sources {
  Sources._();

  static final AudiusSource audius = AudiusSource();
  static final LocalSource local = LocalSource();
  static final CustomSource custom = CustomSource();

  static final List<MusicSource> all = [
    audius,
    local,
    custom,
  ];

  static List<MusicSource> get searchable =>
      all.where((s) => s.canSearch).toList();

  static MusicSource byId(String id) =>
      all.firstWhere((s) => s.id == id, orElse: () => audius);
}
