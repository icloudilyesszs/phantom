import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt_explode;
import 'music_source.dart';
import '../models/track.dart';

class CustomSource implements MusicSource {
  @override
  final String id = 'custom_youtube';

  @override
  final String name = 'YouTube Music';

  @override
  final bool canSearch = true;

  @override
  Future<List<Track>> search(String query) async {
    final url = Uri.parse('https://music.youtube.com/youtubei/v1/search?prettyPrint=false');

    final body = {
      "context": {
        "client": {
          "clientName": "WEB_REMIX",
          "clientVersion": "1.20240724.01.00",
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
              final videoId = song['playlistItemData']?['videoId'] ??
                  song['flexColumns']?[0]?['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs']?[0]?['navigationEndpoint']?['watchEndpoint']?['videoId'];

              final title = song['flexColumns']?[0]?['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs']?[0]?['text'];

              var artist = 'Artiste inconnu';
              final runs = song['flexColumns']?[1]?['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs'] as List?;
              if (runs != null && runs.isNotEmpty) {
                artist = runs[0]?['text'] ?? 'Artiste inconnu';
              }

              int? durationSeconds;
              if (runs != null) {
                for (var r in runs) {
                  final txt = r['text']?.toString() ?? '';
                  if (RegExp(r'^\d+:\d+$').hasMatch(txt)) {
                    final parts = txt.split(':');
                    durationSeconds = int.parse(parts[0]) * 60 + int.parse(parts[1]);
                  }
                }
              }

              String? artUrl;
              final thumbnails = song['thumbnail']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails'] as List?;
              if (thumbnails != null && thumbnails.isNotEmpty) {
                artUrl = thumbnails.last['url']?.toString();
                if (artUrl != null && artUrl.contains('=w')) {
                  artUrl = artUrl.replaceAll(RegExp(r'=w\d+-h\d+.*'), '=w544-h544-l90-rj');
                }
              }

              if (videoId != null && title != null) {
                results.add(Track(
                  id: videoId.toString(),
                  title: title.toString(),
                  artist: artist.toString(),
                  sourceId: id,
                  artworkUrl: artUrl,
                  durationSeconds: durationSeconds,
                ));
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
    return search('Top titres France');
  }

  @override
  Future<Uri> streamUri(Track track) async {
    final yt = yt_explode.YoutubeExplode();
    try {
      final manifest = await yt.videos.streamsClient.getManifest(track.id);
      
      // On récupère directement le meilleur flux audio disponible géré par YoutubeExplode
      final audioStream = manifest.audioOnly.withHighestBitrate();
      final streamUrl = audioStream.url;
      
      yt.close();
      return streamUrl;
    } catch (e) {
      yt.close();
      print('Erreur streamUri YoutubeExplode: $e');
      throw Exception("Impossible de lire ce morceau.");
    }
  }
}
