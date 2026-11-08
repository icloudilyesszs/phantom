import 'dart:convert';
import 'package:http/http.dart' as http;

class CustomSource {
  final String name = "Mon YouTube Music Perso";

  // 1. Recherche directement dans le vrai catalogue YouTube Music
  Future<List>> search(String query) async {
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
        List> results = [];

        // Navigation dans le JSON complexe de YouTube pour extraire les chansons
        final contents = data['contents']?['tabbedSearchResultsRenderer']?['tabs']?[0]?['tabRenderer']?['content']?['sectionListRenderer']?['contents'] ?? [];
        
        for (var section in contents) {
          final musicShelf = section['musicShelfRenderer'];
          if (musicShelf != null) {
            final items = musicShelf['contents'] as List? ?? [];
            for (var item in items) {
              final songRenderer = item['musicResponsiveListItemRenderer'];
              if (songRenderer != null) {
                // Récupérer l'ID de la vidéo/musique
                final videoId = songRenderer['playlistItemData']?['videoId'] ?? 
                                songRenderer['flexColumns']?[0]?['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs']?[0]?['navigationEndpoint']?['watchEndpoint']?['videoId'];
                
                // Titre
                final title = songRenderer['flexColumns']?[0]?['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs']?[0]?['text'] ?? 'Titre inconnu';
                
                // Artiste
                final artist = songRenderer['flexColumns']?[1]?['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs']?[0]?['text'] ?? 'Artiste inconnu';
                
                // Miniature
                final thumbnails = songRenderer['thumbnail']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails'] as List?;
                final artUrl = thumbnails?.isNotEmpty == true ? thumbnails!.last['url'] : '';

                if (videoId != null) {
                  results.add({
                    'id': videoId,
                    'title': title,
                    'artist': artist,
                    'artUrl': artUrl,
                  });
                }
              }
            }
          }
        }
        return results;
      }
    } catch (e) {
      print('Erreur recherche YouTube Music: $e');
    }
    return [];
  }

  // 2. Accueil (laisse vide)
  Future<List>> trending() async {
    return [];
  }

  // 3. Récupère le flux audio direct de la musique sélectionnée
  Future<String?> streamUri(String id) async {
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
      "videoId": id
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
        
        // Filtrer les formats audio et trier par qualité (bitrate)
        final audioFormats = adaptiveFormats.where((format) {
          final mimeType = format['mimeType'] as String? ?? '';
          return mimeType.contains('audio');
        }).toList();

        audioFormats.sort((a, b) => (b['bitrate'] ?? 0).compareTo(a['bitrate'] ?? 0));

        if (audioFormats.isNotEmpty) {
          return audioFormats.first['url'];
        }
      }
    } catch (e) {
      print('Erreur stream audio: $e');
    }
    return null;
  }
}
