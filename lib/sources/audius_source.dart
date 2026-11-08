import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/track.dart';
import 'music_source.dart';

/// Audius : catalogue de musique gratuit et ouvert (api.audius.co).
class AudiusSource implements MusicSource {
  static const _appName = 'Phantom';
  static const _fallbackHost = 'https://discoveryprovider.audius.co';

  String? _host;

  @override
  String get id => 'audius';

  @override
  String get name => 'Audius';

  @override
  bool get canSearch => true;

  Future<String> _getHost() async {
    final cached = _host;
    if (cached != null) return cached;
    try {
      final res = await http
          .get(Uri.parse('https://api.audius.co'))
          .timeout(const Duration(seconds: 8));
      final decoded = jsonDecode(res.body);
      final data = decoded is Map ? decoded['data'] : null;
      if (data is List && data.isNotEmpty) {
        final hosts = data.map((e) => e.toString()).toList()..shuffle();
        _host = hosts.first;
        return hosts.first;
      }
    } catch (_) {
      // on garde le serveur de secours
    }
    _host = _fallbackHost;
    return _fallbackHost;
  }

  List<Track> _parse(String body) {
    final decoded = jsonDecode(body);
    final data = decoded is Map ? decoded['data'] : null;
    if (data is! List) return [];
    final tracks = <Track>[];
    for (final item in data) {
      if (item is! Map) continue;
      final artwork = item['artwork'];
      String? art;
      if (artwork is Map) {
        art = (artwork['480x480'] ?? artwork['150x150'])?.toString();
      }
      final user = item['user'];
      final duration = item['duration'];
      tracks.add(Track(
        id: item['id'].toString(),
        title: (item['title'] ?? 'Sans titre').toString(),
        artist: user is Map ? (user['name'] ?? 'Inconnu').toString() : 'Inconnu',
        artworkUrl: art,
        durationSeconds: duration is num ? duration.toInt() : null,
        sourceId: id,
      ));
    }
    return tracks;
  }

  Future<List<Track>> _get(String path, Map<String, String> params) async {
    final host = await _getHost();
    final uri = Uri.parse('$host$path').replace(
      queryParameters: {...params, 'app_name': _appName},
    );
    final res = await http.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      _host = null; // on retentera un autre serveur la prochaine fois
      throw Exception('Audius ne répond pas (${res.statusCode})');
    }
    return _parse(res.body);
  }

  @override
  Future<List<Track>> search(String query) =>
      _get('/v1/tracks/search', {'query': query});

  @override
  Future<List<Track>> trending() =>
      _get('/v1/tracks/trending', {'limit': '40'});

  @override
  Future<Uri> streamUri(Track track) async {
    final host = await _getHost();
    return Uri.parse('$host/v1/tracks/${track.id}/stream')
        .replace(queryParameters: {'app_name': _appName});
  }
}
