/// A voice note: recorded audio with a transcript.
///
/// The transcript makes the note searchable — asking what someone said
/// about the drive can answer from the transcript. Transcription runs
/// locally when enabled in Settings; in v0.1 the seeded notes carry
/// their transcripts as demo content.
class VoiceNote {
  /// Creates a voice note.
  const VoiceNote({
    required this.id,
    required this.title,
    required this.durationSeconds,
    required this.transcript,
    required this.takenAt,
    required this.waveform,
    this.storyId,
    this.attachedMemoryId,
    this.isDemo = true,
  });

  /// Rebuilds a voice note from stored JSON.
  factory VoiceNote.fromJson(Map<String, Object?> json) => VoiceNote(
        id: json['id'] as String,
        title: json['title'] as String,
        durationSeconds: json['durationSeconds'] as int,
        transcript: json['transcript'] as String,
        takenAt: DateTime.parse(json['takenAt'] as String),
        waveform:
            (json['waveform'] as List<dynamic>).map((v) => (v as num).toDouble()).toList(),
        storyId: json['storyId'] as String?,
        attachedMemoryId: json['attachedMemoryId'] as String?,
        isDemo: json['isDemo'] as bool? ?? true,
      );

  /// Stable id, e.g. `voice-porch`.
  final String id;

  /// Note title, e.g. "Dad, on the porch".
  final String title;

  /// Length in seconds.
  final int durationSeconds;

  /// The searchable transcript.
  final String transcript;

  /// When the note was recorded.
  final DateTime takenAt;

  /// Deterministic waveform bar heights (0–1) for the waveform view.
  final List<double> waveform;

  /// Story the note belongs to, if any.
  final String? storyId;

  /// Memory the note is attached to, if any.
  final String? attachedMemoryId;

  /// True for seeded demo-library content.
  final bool isDemo;

  /// Serializes the voice note for local storage.
  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'title': title,
        'durationSeconds': durationSeconds,
        'transcript': transcript,
        'takenAt': takenAt.toIso8601String(),
        'waveform': waveform,
        'storyId': storyId,
        'attachedMemoryId': attachedMemoryId,
        'isDemo': isDemo,
      };

  /// Returns a copy with the given fields replaced.
  VoiceNote copyWith({String? storyId, String? attachedMemoryId}) => VoiceNote(
        id: id,
        title: title,
        durationSeconds: durationSeconds,
        transcript: transcript,
        takenAt: takenAt,
        waveform: waveform,
        storyId: storyId ?? this.storyId,
        attachedMemoryId: attachedMemoryId ?? this.attachedMemoryId,
        isDemo: isDemo,
      );

  /// Deterministic pseudo-random waveform heights from a seed string.
  /// Pure and stable: the same seed always draws the same waveform.
  static List<double> waveformFor(String seed, {int bars = 48}) {
    var hash = 0;
    for (final unit in seed.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    final heights = <double>[];
    for (var i = 0; i < bars; i++) {
      hash = (hash * 1103515245 + 12345) & 0x7fffffff;
      final envelope = 0.55 + 0.45 * (1 - (i - bars / 2).abs() / (bars / 2));
      heights.add((0.2 + 0.8 * ((hash % 100) / 100)) * envelope);
    }
    return heights;
  }
}
