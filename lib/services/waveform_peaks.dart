import 'dart:math' as math;
import 'dart:typed_data';

/// Real waveform peaks, computed from audio — never invented.
///
/// Two honest sources, in preference order:
///
/// 1. Recorded WAV bytes ([fromWavBytes]): exact peaks from the PCM
///    samples. Voice notes are recorded as WAV (the `record` package
///    encodes WAV on web and native), so this is the normal path.
/// 2. Live amplitude samples ([fromAmplitudes]): dBFS readings taken
///    while recording, used when the bytes cannot be decoded
///    on-device (a non-WAV codec) or the WAV header is unreadable.
///
/// The old deterministic pseudo-random bars (seeded from the note id)
/// are gone: a waveform now means the note was actually recorded, and
/// an empty list means there is no audio to draw.
abstract final class WaveformPeaks {
  /// Default number of bars the waveform widget draws.
  static const int defaultBars = 48;

  /// dBFS floor: readings at or below this read as silence.
  static const double silenceFloorDb = -60;

  /// Computes per-bar peak heights (0–1) from WAV bytes.
  ///
  /// Parses the RIFF header and reads PCM samples: 8/16/24/32-bit
  /// integer and 32-bit float, any channel count (channels collapse
  /// to the loudest sample per frame). Returns an empty list when the
  /// bytes are not a parseable WAV — never throws.
  static List<double> fromWavBytes(Uint8List bytes, {int bars = defaultBars}) {
    if (bars <= 0 || bytes.length < 44) {
      return const <double>[];
    }
    final view = ByteData.sublistView(bytes);
    if (!_isAscii(view, 0, 'RIFF') || !_isAscii(view, 8, 'WAVE')) {
      return const <double>[];
    }
    var format = -1;
    var channels = 0;
    var bitsPerSample = 0;
    var dataOffset = -1;
    var dataLength = 0;
    var offset = 12;
    while (offset + 8 <= bytes.length) {
      final chunkId = String.fromCharCodes(bytes.sublist(offset, offset + 4));
      final chunkSize = view.getUint32(offset + 4, Endian.little);
      final payload = offset + 8;
      if (payload + chunkSize > bytes.length) {
        return const <double>[];
      }
      if (chunkId == 'fmt ' && chunkSize >= 16) {
        format = view.getUint16(payload, Endian.little);
        channels = view.getUint16(payload + 2, Endian.little);
        bitsPerSample = view.getUint16(payload + 14, Endian.little);
      } else if (chunkId == 'data') {
        dataOffset = payload;
        dataLength = chunkSize;
      }
      // Chunks are word-aligned: an odd-sized chunk has a pad byte.
      offset = payload + chunkSize + (chunkSize % 2);
    }
    if (format != 1 && format != 3) {
      return const <double>[];
    }
    if (channels <= 0 || dataOffset < 0 || dataLength <= 0) {
      return const <double>[];
    }
    final bytesPerSample = bitsPerSample ~/ 8;
    if (bytesPerSample <= 0 || bitsPerSample % 8 != 0) {
      return const <double>[];
    }
    final frameSize = bytesPerSample * channels;
    final frameCount = dataLength ~/ frameSize;
    if (frameCount <= 0) {
      return const <double>[];
    }
    final peaks = List<double>.filled(bars, 0);
    final framesPerBar = frameCount / bars;
    for (var frame = 0; frame < frameCount; frame++) {
      final bar = (frame / framesPerBar).floor().clamp(0, bars - 1);
      var loudest = 0.0;
      for (var channel = 0; channel < channels; channel++) {
        final at = dataOffset + frame * frameSize + channel * bytesPerSample;
        final sample = _readSample(view, at, format, bitsPerSample);
        if (sample > loudest) {
          loudest = sample;
        }
      }
      if (loudest > peaks[bar]) {
        peaks[bar] = loudest;
      }
    }
    return peaks;
  }

  /// Computes per-bar peak heights (0–1) from dBFS amplitude samples
  /// taken while recording (see `AudioRecorder.onAmplitudeChanged`).
  ///
  /// Samples are max-pooled into [bars] windows, so a loud moment is
  /// never averaged away. Returns an empty list for empty input.
  static List<double> fromAmplitudes(
    List<double> dbfs, {
    int bars = defaultBars,
  }) {
    if (bars <= 0 || dbfs.isEmpty) {
      return const <double>[];
    }
    final heights = dbfs.map(dbToHeight).toList(growable: false);
    if (heights.length == bars) {
      return heights;
    }
    final peaks = List<double>.filled(bars, 0);
    final perBar = heights.length / bars;
    for (var i = 0; i < heights.length; i++) {
      final bar = (i / perBar).floor().clamp(0, bars - 1);
      if (heights[i] > peaks[bar]) {
        peaks[bar] = heights[i];
      }
    }
    return peaks;
  }

  /// Computes per-bar peak heights (0–1) from signed 16-bit PCM
  /// samples (-32768..32767).
  static List<double> fromPcm16(List<int> samples, {int bars = defaultBars}) {
    if (bars <= 0 || samples.isEmpty) {
      return const <double>[];
    }
    final peaks = List<double>.filled(bars, 0);
    final perBar = samples.length / bars;
    for (var i = 0; i < samples.length; i++) {
      final bar = (i / perBar).floor().clamp(0, bars - 1);
      final height = (samples[i].abs() / 32768).clamp(0.0, 1.0);
      if (height > peaks[bar]) {
        peaks[bar] = height;
      }
    }
    return peaks;
  }

  /// Maps one dBFS reading to a 0–1 height.
  ///
  /// [silenceFloorDb] and below read as 0, 0 dBFS reads as 1, and the
  /// curve is square-rooted so quiet speech stays visible instead of
  /// collapsing to the baseline.
  static double dbToHeight(double db) {
    if (db.isNaN) {
      return 0;
    }
    final linear =
        ((db - silenceFloorDb) / -silenceFloorDb).clamp(0.0, 1.0);
    return math.sqrt(linear);
  }

  static bool _isAscii(ByteData view, int offset, String text) {
    if (offset + text.length > view.lengthInBytes) {
      return false;
    }
    for (var i = 0; i < text.length; i++) {
      if (view.getUint8(offset + i) != text.codeUnitAt(i)) {
        return false;
      }
    }
    return true;
  }

  /// Reads one normalized |sample| (0–1) at [offset] for the given WAV
  /// format (1 = PCM integer, 3 = IEEE float).
  static double _readSample(
    ByteData view,
    int offset,
    int format,
    int bitsPerSample,
  ) {
    if (format == 3) {
      if (bitsPerSample == 32) {
        return view.getFloat32(offset, Endian.little).abs().clamp(0.0, 1.0);
      }
      return 0;
    }
    switch (bitsPerSample) {
      case 8:
        return ((view.getUint8(offset) - 128).abs() / 128).clamp(0.0, 1.0);
      case 16:
        return (view.getInt16(offset, Endian.little).abs() / 32768)
            .clamp(0.0, 1.0);
      case 24:
        var value = view.getUint8(offset) |
            (view.getUint8(offset + 1) << 8) |
            (view.getUint8(offset + 2) << 16);
        if (value & 0x800000 != 0) {
          value -= 0x1000000;
        }
        return (value.abs() / 8388608).clamp(0.0, 1.0);
      case 32:
        return (view.getInt32(offset, Endian.little).abs() / 2147483648)
            .clamp(0.0, 1.0);
      default:
        return 0;
    }
  }
}
