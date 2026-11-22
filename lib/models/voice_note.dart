/// A voice note: recorded audio with a transcript.
///
/// The audio bytes live in the [BlobStore] under [blobId]; the
/// transcript makes the note searchable — asking what someone said
/// about the drive can answer from the transcript. Transcription runs
/// locally when enabled in Settings; notes recorded in-app start with
/// an empty transcript until transcription lands.
///
/// The waveform is real peaks computed from the recording (see
/// `WaveformPeaks`): WAV bytes give exact peaks, anything else falls
/// back to the amplitude samples taken while recording. A note with
/// no stored audio has an empty waveform, and the player says so
/// honestly instead of faking playback.
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
    this.blobId,
    this.mimeType,
    this.isDemo = false,
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
        blobId: json['blobId'] as String?,
        mimeType: json['mimeType'] as String?,
        isDemo: json['isDemo'] as bool? ?? false,
      );

  /// Stable id, e.g. `voice-porch`. A voice note shares its id with
  /// its [MemoryItem] (kind `voiceNote`), so the media detail screen
  /// can open the note from the item and back.
  final String id;

  /// Note title, e.g. "Dad, on the porch".
  final String title;

  /// Length in seconds.
  final int durationSeconds;

  /// The searchable transcript. Empty until transcription lands.
  final String transcript;

  /// When the note was recorded.
  final DateTime takenAt;

  /// Real waveform bar heights (0–1), computed from the recording.
  /// Empty when the note has no audio to draw.
  final List<double> waveform;

  /// Story the note belongs to, if any.
  final String? storyId;

  /// Memory the note is attached to, if any.
  final String? attachedMemoryId;

  /// BlobStore key for the recorded audio bytes. Null for notes
  /// with no stored audio.
  final String? blobId;

  /// MIME type of the recorded audio, e.g. `audio/wav`.
  final String? mimeType;

  /// True for demo-media content (loaded from the bundled demo set).
  /// Real imports and user-created content are false.
  final bool isDemo;

  /// True when this note has recorded audio to play.
  bool get hasAudio => blobId != null;

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
        'blobId': blobId,
        'mimeType': mimeType,
        'isDemo': isDemo,
      };

  /// Returns a copy with the given fields replaced.
  VoiceNote copyWith({
    String? storyId,
    String? attachedMemoryId,
    List<double>? waveform,
    String? blobId,
    String? mimeType,
  }) =>
      VoiceNote(
        id: id,
        title: title,
        durationSeconds: durationSeconds,
        transcript: transcript,
        takenAt: takenAt,
        waveform: waveform ?? this.waveform,
        storyId: storyId ?? this.storyId,
        attachedMemoryId: attachedMemoryId ?? this.attachedMemoryId,
        blobId: blobId ?? this.blobId,
        mimeType: mimeType ?? this.mimeType,
        isDemo: isDemo,
      );
}
