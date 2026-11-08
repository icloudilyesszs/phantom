import 'dart:convert';
import 'package:http/http.dart' as http;
import 'music_source.dart';
import '../models/track.dart';

class CustomSource implements MusicSource {
  @override
  final String id = 'custom_youtube';

  @override
  final String name = 'YouTube Music (Complet)';

  @override
  final bool canSearch = true;

  @override
  Future<List<Track>> search(String query) async {
    final url = Uri.parse('https://music.youtube.com/youtubei/v1/search?key=AIzaSyA41KXq462b13wV8o3_2J0vN2V_K4c5Y9Q');
    
    final body = {
      "context": {
        "client": {
          "clientName": "WEB_REMIX",
          "clientVersion": "1.20240220.01.00",
          "hl": "fr",
          "gl": "FR"
        }
      },
      "query": query,
      "params": "EgWKAQIIAWoMEAMQBBAJEA4QChAF"
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<Track> results = [];

        final tabs = data['contents']?['tabbedSearchResultsRenderer']?['tabs'] as List? ?? [];
        if (tabs.isEmpty) return [];
        
        final sectionList = tabs[0]?['tabRenderer']?['content']?['sectionListRenderer']?['contents'] as List? ?? [];
        
        for (var section in sectionList) {
          final items = section['musicShelfRenderer']?['contents'] as List? ?? [];
          for (var item in items) {
            final song = item['musicResponsiveListItemRenderer'];
            if (song != null) {
              final videoId = song['playlistItemData']?['videoId'];
              final title = song['flexColumns']?[0]?['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs']?[0]?['text'];
              
              var artist = 'Artiste inconnu';
              final runs = song['flexColumns']?[1]?['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs'] as List?;
              if (runs != null && runs.isNotEmpty) {
                artist = runs[0]?['text'] ?? 'Artiste inconnu';
              }

              String? artUrl;
              final thumbnails = song['thumbnail']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails'] as List?;
              if (thumbnails != null && thumbnails.isNotEmpty) {
                // Récupère l'image avec la meilleure résolution disponible
                artUrl = thumbnails.last['url']?.toString();
              }

              if (videoId != null && title != null) {
                results.add(Track(
                  id: videoId.toString(),
                  title: title.toString(),
                  artist: artist.toString(),
                  sourceId: id,
                  artworkUrl: artUrl,
                ));
              }
            }
          }
        }
        return results;
      }
    } catch (e) {
      print('Erreur: $e');
    }
    return [];
  }

  @override
  Future<List<Track>> trending() async {
    return [];
  }

  @override
  Future<Uri> streamUri(Track track) async {
    final url = Uri.parse('https://pipedapi.kavin.rocks/streams/${track.id}');
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final audioStreams = data['audioStreams'] as List? ?? [];
        
        // Trie pour récupérer le flux audio avec la meilleure qualité
        audioStreams.sort((a, b) => (b['bitrate'] ?? 0).compareTo(a['bitrate'] ?? 0));
        
        if (audioStreams.isNotEmpty) {
          final rawUrl = audioStreams.first['url'] as String?;
          if (rawUrl != null) {
            return Uri.parse(rawUrl);
          }
        }
      }
    } catch (e) {
      print('Erreur stream Piped: $e');
    }
    throw Exception("Impossible de récupérer le flux audio YouTube");
  }
}
