import 'dart:convert';
import 'package:http/http.dart' as http;
import 'music_source.dart';
import '../models/track.dart';

class CustomSource implements MusicSource {
  @override
  final String id = 'custom_youtube';

  @override
  final String name = 'Mon YouTube Music Perso';

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
      "query": query
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

        final contents = data['contents']?['tabbedSearchResultsRenderer']?['tabs']?[0]?['tabRenderer']?['content']?['sectionListRenderer']?['contents'] ?? [];
        
        for (var section in contents) {
          final musicShelf = section['musicShelfRenderer'];
          if (musicShelf != null) {
            final items = musicShelf['contents'] as List? ?? [];
            for (var item in items) {
              final songRenderer = item['musicResponsiveListItemRenderer'];
              if (songRenderer != null) {
                final videoId = songRenderer['playlistItemData']?['videoId'] ?? 
                                songRenderer['flexColumns']?[0]?['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs']?[0]?['navigationEndpoint']?['watchEndpoint']?['videoId'];
                
                final title = songRenderer['flexColumns']?[0]?['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs']?[0]?['text'] ?? 'Titre inconnu';
                
                final artist = songRenderer['flexColumns']?[1]?['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs']?[0]?['text'] ?? 'Artiste inconnu';

                if (videoId != null) {
                  results.add(Track(
                    id: videoId,
                    title: title,
                    artist: artist,
                    sourceId: id,
                  ));
                }
              }
            }
          }
        }
        return results;
      }
    } catch (e) {
      print('Erreur recherche: $e');
    }
    return [];
  }

  @override
  Future<List<Track>> trending() async {
    return [];
  }

  @override
  Future<Uri> streamUri(Track track) async {
    final url = Uri.parse('https://music.youtube.com/youtubei/v1/player?key=AIzaSyA41KXq462b13wV8o3_2J0vN2V_K4c5Y9Q');
    
    final body = {
      "context": {
        "client": {
          "clientName": "WEB_REMIX",
          "clientVersion": "1.20240220.01.00",
          "hl": "fr",
          "gl": "FR"
        }
      },
      "videoId": track.id
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final adaptiveFormats = data['streamingData']?['adaptiveFormats'] as List? ?? [];
        
        final audioFormats = adaptiveFormats.where((format) {
          final mimeType = format['mimeType'] as String? ?? '';
          return mimeType.contains('audio');
        }).toList();

        audioFormats.sort((a, b) => (b['bitrate'] ?? 0).compareTo(a['bitrate'] ?? 0));

        if (audioFormats.isNotEmpty) {
          final rawUrl = audioFormats.first['url'] as String?;
          if (rawUrl != null) {
            return Uri.parse(rawUrl);
          }
        }
      }
    } catch (e) {
      print('Erreur stream: $e');
    }
    throw Exception("Impossible de récupérer le flux audio");
  }
}
