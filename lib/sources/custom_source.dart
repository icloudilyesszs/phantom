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
      "params": "EgWKAQIIAWoMEAMQBBAJEA4QChAF" // Filtre officiel BitChord (Songs)
    };

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36",
          "Origin": "https://music.youtube.com",
          "Referer": "https://music.youtube.com/",
        },
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
                // Force l'image en haute définition (544x544) comme sur BitChord
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
      print('Erreur recherche YTM: $e');
    }
    return [];
  }

  @override
  Future<List<Track>> trending() async {
    // Charge un top par défaut sur l'accueil si nécessaire
    return search('Top titres France');
  }

  @override
  Future<Uri> streamUri(Track track) async {
    // 1. Méthode principale de BitChord : extraction directe InnerTube (Clients iOS & Android VR)
    // Ces clients fournissent des URLs M4A (AAC) directes sans chiffrement cipher ni blocage.
    final directUri = await _extractDirectInnerTubeStream(track.id);
    if (directUri != null) {
      return directUri;
    }

    // 2. Fallback de sécurité : YoutubeExplode avec priorité stricte sur le conteneur MP4/M4A (itag 140)
    final yt = yt_explode.YoutubeExplode();
    try {
      final manifest = await yt.videos.streamsClient.getManifest(track.id);

      // On cherche en priorité le flux itag 140 (M4A AAC 128kbps), supporté nativement par Windows Media Kit et iOS AVPlayer
      final m4aStreams = manifest.audioOnly.where((s) =>
          s.tag == 140 ||
          s.container.name.toLowerCase() == 'mp4' ||
          s.codec.mimeType.toLowerCase().contains('mp4')).toList();

      if (m4aStreams.isNotEmpty) {
        m4aStreams.sort((a, b) => b.bitrate.bitsPerSecond.compareTo(a.bitrate.bitsPerSecond));
        final url = m4aStreams.first.url;
        yt.close();
        return url;
      }

      if (manifest.muxed.isNotEmpty) {
        final url = manifest.muxed.withHighestBitrate().url;
        yt.close();
        return url;
      }

      final url = manifest.audioOnly.withHighestBitrate().url;
      yt.close();
      return url;
    } catch (e) {
      yt.close();
      print('Erreur fallback YoutubeExplode: $e');
    }

    throw Exception("Impossible de récupérer le flux audio pour ${track.title}");
  }

  /// Interroge l'API interne de YouTube exactement comme BitChord en simulant un appareil iOS ou Android VR
  Future<Uri?> _extractDirectInnerTubeStream(String videoId) async {
    final clients = [
      {
        "name": "IOS",
        "userAgent": "com.google.ios.youtube/19.29.1 (iPhone16,2; U; CPU iOS 17_5_1 like Mac OS X;)",
        "clientId": "5",
        "context": {
          "client": {
            "clientName": "IOS",
            "clientVersion": "19.29.1",
            "deviceMake": "Apple",
            "deviceModel": "iPhone16,2",
            "osName": "iPhone",
            "osVersion": "17.5.1.21F90",
            "hl": "fr",
            "gl": "FR"
          }
        }
      },
      {
        "name": "ANDROID_VR",
        "userAgent": "com.google.android.apps.youtube.vr.oculus/1.56.21 (Linux; U; Android 12L; eureka-user Build/SQ3A.220605.009.A1) gzip",
        "clientId": "28",
        "context": {
          "client": {
            "clientName": "ANDROID_VR",
            "clientVersion": "1.56.21",
            "deviceMake": "Oculus",
            "deviceModel": "Quest 3",
            "osName": "Android",
            "osVersion": "12L",
            "androidSdkVersion": 32,
            "hl": "fr",
            "gl": "FR"
          }
        }
      },
    ];

    final url = Uri.parse('https://www.youtube.com/youtubei/v1/player?prettyPrint=false');

    for (final client in clients) {
      try {
        final response = await http.post(
          url,
          headers: {
            "Content-Type": "application/json",
            "User-Agent": client["userAgent"] as String,
            "X-YouTube-Client-Name": client["clientId"] as String,
          },
          body: jsonEncode({
            "context": client["context"],
            "videoId": videoId,
            "contentCheckOk": true,
            "racyCheckOk": true,
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final playability = data['playabilityStatus']?['status'];
          if (playability != 'OK') continue;

          final adaptiveFormats = data['streamingData']?['adaptiveFormats'] as List? ?? [];
          final regularFormats = data['streamingData']?['formats'] as List? ?? [];

          // 1. Chercher en priorité absolue le flux M4A (audio/mp4 - itag 140)
          final mp4Audio = adaptiveFormats.where((f) {
            final mime = (f['mimeType'] ?? '').toString().toLowerCase();
            return mime.contains('audio/mp4') && f['url'] != null;
          }).toList();

          if (mp4Audio.isNotEmpty) {
            mp4Audio.sort((a, b) => (b['bitrate'] ?? 0).compareTo(a['bitrate'] ?? 0));
            return Uri.parse(mp4Audio.first['url'].toString());
          }

          // 2. Sinon chercher un flux MP4 standard (formats combinés)
          for (final f in regularFormats) {
            if (f['url'] != null) {
              return Uri.parse(f['url'].toString());
            }
          }

          // 3. Sinon tout autre flux audio direct disponible
          final anyAudio = adaptiveFormats.where((f) {
            final mime = (f['mimeType'] ?? '').toString().toLowerCase();
            return mime.contains('audio') && f['url'] != null;
          }).toList();

          if (anyAudio.isNotEmpty) {
            anyAudio.sort((a, b) => (b['bitrate'] ?? 0).compareTo(a['bitrate'] ?? 0));
            return Uri.parse(anyAudio.first['url'].toString());
          }
        }
      } catch (e) {
        print('Erreur client ${client["name"]}: $e');
      }
    }
    return null;
  }
}
