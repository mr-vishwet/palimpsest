import 'dart:async';

import 'package:crypto/crypto.dart';
import 'package:record/record.dart';

import '../models/memory_item.dart';
import '../models/voice_note.dart';
import 'blob_store.dart';
import 'blob_store_access.dart';
import 'voice_bytes.dart' as voice_bytes;
import 'waveform_peaks.dart';

/// The outcome of one finished recording: the voice note and its
/// memory item, ready for the archive controller to persist.
///
/// The caller hands both to `ArchiveController.addVoiceNote` — the
/// recorder itself never touches the archive document.
class RecordedVoiceNote {
  /// Creates a recorded voice note result.
  const RecordedVoiceNote({required this.note, required this.item});

  /// The voice note, with real peaks and a BlobStore key.
  final VoiceNote note;

  /// The matching memory item (kind `voiceNote`, same id).
  final MemoryItem item;
}

/// Records voice notes with the device microphone and stores the real
/// audio bytes in the [BlobStore].
///
/// Recording is WAV, 16 kHz mono: small enough for spoken notes and
/// decodable on-device, so the waveform is computed from the actual
/// PCM samples ([WaveformPeaks.fromWavBytes]). Amplitude samples are
/// collected while recording as a live level meter and as the
/// fallback waveform when the bytes cannot be decoded.
///
/// Microphone permission is requested honestly through
/// [ensurePermission]: when the user says no, [start] returns false
/// and the screen explains that recording needs the microphone —
/// nothing is recorded silently, and nothing is faked.
class VoiceRecorderService {
  /// Creates a recorder. Pass [blobStore] in tests; otherwise the
  /// app-wide store from [BlobStoreAccess] is used.
  VoiceRecorderService({BlobStore? blobStore}) : _blobStore = blobStore;

  /// Sample rate for recordings: speech needs no more than 16 kHz.
  static const int sampleRate = 16000;

  /// How often amplitude is sampled while recording.
  static const Duration amplitudeInterval = Duration(milliseconds: 200);

  final BlobStore? _blobStore;
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Amplitude>? _amplitudeSub;
  final StreamController<double> _levelController =
      StreamController<double>.broadcast();
  final List<double> _amplitudes = <double>[];
  DateTime? _startedAt;
  bool _disposed = false;

  /// Live recording level, 0–1, for the level meter.
  Stream<double> get liveLevel => _levelController.stream;

  /// True while a recording is in progress.
  bool get isRecording => _startedAt != null;

  /// Checks (and, on first use, requests) microphone permission.
  /// Returns false when the user declines — the caller explains why
  /// recording needs the microphone.
  Future<bool> ensurePermission() => _recorder.hasPermission();

  /// Starts recording. Returns false when permission is denied or no
  /// blob store is registered — the caller shows the honest reason.
  Future<bool> start() async {
    if (_disposed || _startedAt != null) {
      return false;
    }
    final store = _blobStore ?? BlobStoreAccess.current;
    if (store == null) {
      return false;
    }
    if (!await _recorder.hasPermission()) {
      return false;
    }
    _amplitudes.clear();
    _startedAt = DateTime.now();
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: sampleRate,
        numChannels: 1,
      ),
      path: voice_bytes.recordingPath(),
    );
    _amplitudeSub =
        _recorder.onAmplitudeChanged(amplitudeInterval).listen((amplitude) {
      _amplitudes.add(amplitude.current);
      if (!_levelController.isClosed) {
        _levelController.add(WaveformPeaks.dbToHeight(amplitude.current));
      }
    });
    return true;
  }

  /// Stops the recording, stores the bytes, and builds the note and
  /// item. Returns null when nothing was recording.
  ///
  /// The waveform comes from the recorded WAV bytes; when the bytes
  /// cannot be decoded, the amplitude samples taken while recording
  /// are used instead. The note starts with an empty transcript —
  /// transcription is a separate, not-yet-built feature.
  Future<RecordedVoiceNote?> stopAndSave({
    required String title,
    String? storyId,
  }) async {
    final startedAt = _startedAt;
    if (startedAt == null) {
      return null;
    }
    final store = _blobStore ?? BlobStoreAccess.current;
    if (store == null) {
      throw StateError('No blob store is registered.');
    }
    await _amplitudeSub?.cancel();
    _amplitudeSub = null;
    final path = await _recorder.stop();
    final elapsed = DateTime.now().difference(startedAt);
    _startedAt = null;
    final bytes = await voice_bytes.readRecordedBytes(path);
    final peaks = WaveformPeaks.fromWavBytes(bytes);
    final waveform = peaks.isNotEmpty
        ? peaks
        : WaveformPeaks.fromAmplitudes(_amplitudes);
    final blobId = await store.put(bytes);
    final checksum = sha256.convert(bytes).toString();
    final id = 'voice-${startedAt.millisecondsSinceEpoch}';
    final durationSeconds = elapsed.inSeconds;
    final note = VoiceNote(
      id: id,
      title: title,
      durationSeconds: durationSeconds,
      transcript: '',
      takenAt: startedAt,
      waveform: waveform,
      storyId: storyId,
      blobId: blobId,
      mimeType: 'audio/wav',
      isDemo: false,
    );
    final item = MemoryItem(
      id: id,
      kind: MediaKind.voiceNote,
      title: title,
      takenAt: startedAt,
      checksum: checksum,
      storyId: storyId,
      durationSeconds: durationSeconds,
      blobId: blobId,
      mimeType: 'audio/wav',
      sourceName: '$title.wav',
      isDemo: false,
    );
    return RecordedVoiceNote(note: note, item: item);
  }

  /// Discards the current recording, if any.
  Future<void> cancel() async {
    if (_startedAt == null) {
      return;
    }
    await _amplitudeSub?.cancel();
    _amplitudeSub = null;
    await _recorder.cancel();
    _startedAt = null;
    _amplitudes.clear();
  }

  /// Releases the recorder and the level stream.
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    await cancel();
    await _levelController.close();
    await _recorder.dispose();
  }
}
