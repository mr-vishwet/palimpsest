import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../models/voice_note.dart';
import 'blob_store.dart';
import 'blob_store_access.dart';

/// Real audio playback for voice notes, from the bytes in the
/// [BlobStore].
///
/// [load] fetches the note's bytes and hands them to the player as
/// in-memory audio (`AudioPlayer.setSourceBytes` — on web the player
/// turns the bytes into a blob URL itself). A note with no stored
/// audio (a note with no stored audio) fails to load honestly: [load] returns
/// false and the screen says the note has no recording, instead of
/// animating a fake playhead.
class AudioPlaybackController extends ChangeNotifier {
  /// Creates a playback controller. Pass [player] and [blobStore] in
  /// tests; otherwise a fresh player and the app-wide store are used.
  AudioPlaybackController({AudioPlayer? player, BlobStore? blobStore})
      : _player = player ?? AudioPlayer(),
        _blobStore = blobStore {
    _subscriptions.addAll(<StreamSubscription<dynamic>>[
      _player.onDurationChanged.listen((duration) {
        _duration = duration;
        notifyListeners();
      }),
      _player.onPositionChanged.listen((position) {
        _position = position;
        notifyListeners();
      }),
      _player.onPlayerStateChanged.listen((state) {
        _playing = state == PlayerState.playing;
        notifyListeners();
      }),
      _player.onPlayerComplete.listen((_) {
        _playing = false;
        _position = _duration;
        notifyListeners();
      }),
    ]);
  }

  final AudioPlayer _player;
  final BlobStore? _blobStore;
  final List<StreamSubscription<dynamic>> _subscriptions =
      <StreamSubscription<dynamic>>[];

  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _playing = false;
  bool _loaded = false;
  String? _noteId;

  /// True once a note's audio has loaded and is ready to play.
  bool get isLoaded => _loaded;

  /// True while audio is playing.
  bool get isPlaying => _playing;

  /// Total length of the loaded audio (zero until the player reports
  /// it).
  Duration get duration => _duration;

  /// Current playback position.
  Duration get position => _position;

  /// Playback progress, 0–1.
  double get progress {
    if (_duration.inMilliseconds <= 0) {
      return 0;
    }
    return (_position.inMilliseconds / _duration.inMilliseconds)
        .clamp(0.0, 1.0);
  }

  /// Loads [note]'s audio from the BlobStore. Returns false when the
  /// note has no stored audio or the bytes are gone.
  Future<bool> load(VoiceNote note) async {
    if (_noteId == note.id && _loaded) {
      return true;
    }
    final blobId = note.blobId;
    final store = _blobStore ?? BlobStoreAccess.current;
    if (blobId == null || store == null) {
      return false;
    }
    final bytes = await store.get(blobId);
    if (bytes == null) {
      return false;
    }
    await _player.stop();
    await _player.setSourceBytes(bytes, mimeType: note.mimeType);
    _noteId = note.id;
    _loaded = true;
    _position = Duration.zero;
    _playing = false;
    notifyListeners();
    return true;
  }

  /// Plays the loaded audio from the current position.
  Future<void> play() async {
    if (!_loaded) {
      return;
    }
    if (_position >= _duration && _duration > Duration.zero) {
      await _player.seek(Duration.zero);
    }
    await _player.resume();
  }

  /// Pauses playback, keeping the position.
  Future<void> pause() => _player.pause();

  /// Seeks to [position] within the loaded audio.
  Future<void> seek(Duration position) async {
    if (!_loaded) {
      return;
    }
    final clamped = Duration(
      milliseconds: position.inMilliseconds.clamp(0, _duration.inMilliseconds),
    );
    await _player.seek(clamped);
    _position = clamped;
    notifyListeners();
  }

  /// Stops playback and returns to the start.
  Future<void> stop() async {
    await _player.stop();
    _position = Duration.zero;
    _playing = false;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _player.dispose();
    super.dispose();
  }
}
