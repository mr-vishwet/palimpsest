import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:palimpsest/models/voice_note.dart';
import 'package:palimpsest/services/waveform_peaks.dart';

/// Builds a minimal WAV (RIFF + fmt + data) from 16-bit mono PCM
/// samples, so the peak tests run on bytes a real recorder produces.
Uint8List buildWav16(List<int> samples, {int sampleRate = 8000}) {
  final dataSize = samples.length * 2;
  final bytes = Uint8List(44 + dataSize);
  final view = ByteData.sublistView(bytes);
  void ascii(int offset, String text) {
    for (var i = 0; i < text.length; i++) {
      bytes[offset + i] = text.codeUnitAt(i);
    }
  }

  ascii(0, 'RIFF');
  view.setUint32(4, 36 + dataSize, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  view.setUint32(16, 16, Endian.little);
  view.setUint16(20, 1, Endian.little); // PCM
  view.setUint16(22, 1, Endian.little); // mono
  view.setUint32(24, sampleRate, Endian.little);
  view.setUint32(28, sampleRate * 2, Endian.little);
  view.setUint16(32, 2, Endian.little);
  view.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  view.setUint32(40, dataSize, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    view.setInt16(44 + i * 2, samples[i], Endian.little);
  }
  return bytes;
}

void main() {
  group('WaveformPeaks.fromWavBytes', () {
    test('returns 48 bars by default', () {
      final wav = buildWav16(List<int>.filled(480, 1000));
      expect(WaveformPeaks.fromWavBytes(wav).length, 48);
    });

    test('peaks track the loudest part of the recording', () {
      // First half silence, second half full-scale.
      final samples = <int>[
        ...List<int>.filled(240, 0),
        ...List<int>.filled(240, 32767),
      ];
      final peaks = WaveformPeaks.fromWavBytes(wavFor(samples));
      expect(peaks.sublist(0, 24).every((p) => p == 0), isTrue);
      expect(peaks.sublist(24).every((p) => p > 0.99), isTrue);
    });

    test('a half-scale tone peaks near 0.5', () {
      final wav = buildWav16(List<int>.filled(480, 16384));
      final peaks = WaveformPeaks.fromWavBytes(wav);
      expect(peaks.every((p) => (p - 0.5).abs() < 0.01), isTrue);
    });

    test('stereo takes the loudest channel per frame', () {
      // Interleaved stereo: left silent, right full-scale.
      final bytes = Uint8List(44 + 480 * 2 * 2);
      final view = ByteData.sublistView(bytes);
      void ascii(int offset, String text) {
        for (var i = 0; i < text.length; i++) {
          bytes[offset + i] = text.codeUnitAt(i);
        }
      }

      ascii(0, 'RIFF');
      view.setUint32(4, 36 + 480 * 4, Endian.little);
      ascii(8, 'WAVE');
      ascii(12, 'fmt ');
      view.setUint32(16, 16, Endian.little);
      view.setUint16(20, 1, Endian.little);
      view.setUint16(22, 2, Endian.little); // stereo
      view.setUint32(24, 8000, Endian.little);
      view.setUint32(28, 8000 * 4, Endian.little);
      view.setUint16(32, 4, Endian.little);
      view.setUint16(34, 16, Endian.little);
      ascii(36, 'data');
      view.setUint32(40, 480 * 4, Endian.little);
      for (var i = 0; i < 480; i++) {
        view.setInt16(44 + i * 4, 0, Endian.little);
        view.setInt16(44 + i * 4 + 2, 32767, Endian.little);
      }
      final peaks = WaveformPeaks.fromWavBytes(bytes);
      expect(peaks.every((p) => p > 0.99), isTrue);
    });

    test('garbage bytes return an empty list, never a throw', () {
      expect(WaveformPeaks.fromWavBytes(Uint8List(0)), isEmpty);
      expect(
        WaveformPeaks.fromWavBytes(Uint8List.fromList('not a wav'.codeUnits)),
        isEmpty,
      );
      final truncated = buildWav16(List<int>.filled(100, 1000)).sublist(0, 30);
      expect(WaveformPeaks.fromWavBytes(truncated), isEmpty);
    });
  });

  group('WaveformPeaks.fromPcm16', () {
    test('silence is flat zero', () {
      final peaks = WaveformPeaks.fromPcm16(
        List<int>.filled(96, 0),
        bars: 8,
      );
      expect(peaks, List<double>.filled(8, 0));
    });

    test('a single loud sample shows in its own bar', () {
      final samples = List<int>.filled(80, 0);
      samples[79] = 32767;
      final peaks = WaveformPeaks.fromPcm16(samples, bars: 8);
      expect(peaks.sublist(0, 7).every((p) => p == 0), isTrue);
      expect(peaks[7], greaterThan(0.99));
    });
  });

  group('WaveformPeaks.fromAmplitudes', () {
    test('dBFS maps to heights: 0 dB is full, -60 dB is silence', () {
      expect(WaveformPeaks.dbToHeight(0), 1);
      expect(WaveformPeaks.dbToHeight(-60), 0);
      expect(WaveformPeaks.dbToHeight(-160), 0);
      expect(WaveformPeaks.dbToHeight(double.nan), 0);
      expect(WaveformPeaks.dbToHeight(6), 1);
    });

    test('max-pooling keeps a loud moment instead of averaging it away', () {
      final peaks = WaveformPeaks.fromAmplitudes(
        <double>[-60, -60, 0, -60],
        bars: 2,
      );
      expect(peaks[0], 0);
      expect(peaks[1], 1);
    });

    test('empty input returns an empty list', () {
      expect(WaveformPeaks.fromAmplitudes(<double>[]), isEmpty);
    });
  });

  group('VoiceNote model', () {
    final note = VoiceNote(
      id: 'voice-test',
      title: 'Test note',
      durationSeconds: 12,
      transcript: '',
      takenAt: DateTime.utc(2026, 11, 23, 12),
      waveform: const <double>[0.1, 0.9, 0.4],
      blobId: 'abc123',
      mimeType: 'audio/wav',
      isDemo: false,
    );

    test('blobId and mimeType survive a JSON round-trip', () {
      final rebuilt = VoiceNote.fromJson(note.toJson());
      expect(rebuilt.blobId, 'abc123');
      expect(rebuilt.mimeType, 'audio/wav');
      expect(rebuilt.waveform, const <double>[0.1, 0.9, 0.4]);
      expect(rebuilt.hasAudio, isTrue);
    });

    test('legacy JSON without audio fields loads with nulls', () {
      final rebuilt = VoiceNote.fromJson(<String, Object?>{
        'id': 'voice-old',
        'title': 'Old note',
        'durationSeconds': 5,
        'transcript': 'hello',
        'takenAt': '2026-01-01T00:00:00.000Z',
        'waveform': const <double>[0.5],
      });
      expect(rebuilt.blobId, isNull);
      expect(rebuilt.mimeType, isNull);
      expect(rebuilt.hasAudio, isFalse);
    });

    test('copyWith carries the audio fields', () {
      final copied = note.copyWith(storyId: 'story-1');
      expect(copied.blobId, 'abc123');
      expect(copied.mimeType, 'audio/wav');
      expect(copied.storyId, 'story-1');
      final replaced = note.copyWith(waveform: const <double>[0.2]);
      expect(replaced.waveform, const <double>[0.2]);
      expect(replaced.blobId, 'abc123');
    });
  });
}

/// Shorthand so the stereo test reads cleanly.
Uint8List wavFor(List<int> samples) => buildWav16(samples);
