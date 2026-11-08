import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/track.dart';
import '../sources/sources.dart';

/// Tout ce que l'utilisateur garde : fichiers importés, playlists, titres likés.
class LibraryService extends ChangeNotifier {
  static const _kLocal = 'phantom.local';
  static const _kPlaylists = 'phantom.playlists';
  static const _kLiked = 'phantom.liked';

  List<Track> localTracks = [];
  Map<String, List<Track>> playlists = {};
  List<Track> liked = [];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    localTracks = _decodeList(prefs.getString(_kLocal));
    liked = _decodeList(prefs.getString(_kLiked));
    final raw = prefs.getString(_kPlaylists);
    if (raw != null) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        playlists = map.map(
          (name, list) => MapEntry(
            name,
            (list as List)
                .map((e) => Track.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList(),
          ),
        );
      } catch (_) {
        playlists = {};
      }
    }
    notifyListeners();
  }

  List<Track> _decodeList(String? raw) {
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => Track.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _kLocal, jsonEncode(localTracks.map((t) => t.toJson()).toList()));
    await prefs.setString(
        _kLiked, jsonEncode(liked.map((t) => t.toJson()).toList()));
    await prefs.setString(
      _kPlaylists,
      jsonEncode(playlists.map(
        (name, list) => MapEntry(name, list.map((t) => t.toJson()).toList()),
      )),
    );
    notifyListeners();
  }

  // ---- Fichiers locaux ----
  Future<int> importLocal() async {
    final added = await Sources.local.importFiles();
    var count = 0;
    for (final t in added) {
      if (!localTracks.contains(t)) {
        localTracks.add(t);
        count++;
      }
    }
    await _save();
    return count;
  }

  Future<void> removeLocal(Track track) async {
    localTracks.remove(track);
    liked.remove(track);
    for (final list in playlists.values) {
      list.remove(track);
    }
    await Sources.local.deleteFile(track);
    await _save();
  }

  // ---- J'aime ----
  bool isLiked(Track track) => liked.contains(track);

  Future<void> toggleLike(Track track) async {
    if (liked.contains(track)) {
      liked.remove(track);
    } else {
      liked.insert(0, track);
    }
    await _save();
  }

  // ---- Playlists ----
  Future<bool> createPlaylist(String name) async {
    final clean = name.trim();
    if (clean.isEmpty || playlists.containsKey(clean)) return false;
    playlists[clean] = [];
    await _save();
    return true;
  }

  Future<void> deletePlaylist(String name) async {
    playlists.remove(name);
    await _save();
  }

  Future<void> addToPlaylist(String name, Track track) async {
    final list = playlists[name];
    if (list == null || list.contains(track)) return;
    list.add(track);
    await _save();
  }

  Future<void> removeFromPlaylist(String name, Track track) async {
    playlists[name]?.remove(track);
    await _save();
  }
}
