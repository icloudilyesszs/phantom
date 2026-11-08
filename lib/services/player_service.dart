import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../models/track.dart';
import '../sources/sources.dart';

/// Gère la lecture : file d'attente, suivant/précédent, lecture aléatoire.
class PlayerService extends ChangeNotifier {
  final AudioPlayer player = AudioPlayer();

  List<Track> _queue = [];
  int _index = -1;
  bool shuffle = false;
  bool repeatOne = false;
  String? error;
  bool loading = false;

  final List<StreamSubscription> _subs = [];

  PlayerService() {
    _subs.add(player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _onCompleted();
      }
      notifyListeners();
    }));
  }

  List<Track> get queue => List.unmodifiable(_queue);
  int get index => _index;
  Track? get current =>
      (_index >= 0 && _index < _queue.length) ? _queue[_index] : null;
  bool get isPlaying => player.playing;

  Future<void> playList(List<Track> tracks, int start) async {
    if (tracks.isEmpty) return;
    _queue = List.of(tracks);
    _index = start.clamp(0, _queue.length - 1);
    await _load();
  }

  Future<void> _load() async {
    final track = current;
    if (track == null) return;
    error = null;
    loading = true;
    notifyListeners();
    try {
      final tag = MediaItem(
        id: track.key,
        title: track.title,
        artist: track.artist,
        artUri: track.artworkUrl != null ? Uri.parse(track.artworkUrl!) : null,
      );
      final AudioSource source;
      if (track.localPath != null) {
        source = AudioSource.file(track.localPath!, tag: tag);
      } else {
        final uri = await Sources.byId(track.sourceId).streamUri(track);
        source = AudioSource.uri(uri, tag: tag);
      }
      // preload: false = on ne bloque pas en attendant que tout soit chargé
      await player
          .setAudioSource(source, preload: false)
          .timeout(const Duration(seconds: 20));
      loading = false;
      notifyListeners();
      unawaited(player.play().catchError((Object e) {
        error = 'Impossible de lire "${track.title}"';
        debugPrint('Erreur lecture: $e');
        notifyListeners();
      }));
    } catch (e) {
      loading = false;
      error = 'Impossible de lire "${track.title}"';
      debugPrint('Erreur lecture: $e');
      notifyListeners();
    }
  }

  bool _handlingEnd = false;
  Future<void> _onCompleted() async {
    if (_handlingEnd) return;
    _handlingEnd = true;
    try {
      if (repeatOne) {
        await player.seek(Duration.zero);
        unawaited(player.play());
      } else if (_hasNext) {
        await next();
      } else {
        await player.pause();
        await player.seek(Duration.zero);
      }
    } finally {
      _handlingEnd = false;
    }
  }

  bool get _hasNext => shuffle ? _queue.length > 1 : _index < _queue.length - 1;

  Future<void> next() async {
    if (_queue.isEmpty) return;
    if (shuffle && _queue.length > 1) {
      var n = _index;
      while (n == _index) {
        n = (DateTime.now().microsecondsSinceEpoch % _queue.length);
      }
      _index = n;
    } else {
      _index = (_index + 1) % _queue.length;
    }
    await _load();
  }

  Future<void> previous() async {
    if (_queue.isEmpty) return;
    if (player.position > const Duration(seconds: 3)) {
      await player.seek(Duration.zero);
      return;
    }
    _index = (_index - 1 + _queue.length) % _queue.length;
    await _load();
  }

  Future<void> toggle() async {
    if (current == null) return;
    if (player.playing) {
      await player.pause();
    } else {
      unawaited(player.play());
    }
    notifyListeners();
  }

  void toggleShuffle() {
    shuffle = !shuffle;
    notifyListeners();
  }

  void toggleRepeat() {
    repeatOne = !repeatOne;
    notifyListeners();
  }

  Future<void> seek(Duration d) => player.seek(d);

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    player.dispose();
    super.dispose();
  }
}
