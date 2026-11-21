import 'dart:convert';

import 'package:crypto/crypto.dart';

/// The kind of a single memory in the archive.
enum MediaKind {
  /// A still photo.
  photo,

  /// A video clip.
  video,

  /// A recorded voice note (also listed in [VoiceNote] for playback).
  voiceNote,

  /// A written note attached to a moment.
  note,
}

/// A single memory: one photo, video, voice note or written note.
///
/// The provenance contract (catalog): every memory links to a source id
/// and a checksum, so any search result or export can be traced back to
/// the item it came from. In v0.1 the seeded demo library carries
/// deterministic checksums computed from id + timestamp; real imports
/// hash the file bytes (phase 2).
class MemoryItem {
  /// Creates a memory item.
  const MemoryItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.takenAt,
    required this.checksum,
    this.storyId,
    this.chapterId,
    this.tags = const <String>[],
    this.personIds = const <String>[],
    this.placeId,
    this.aspectRatio = '4:3',
    this.widthPx = 0,
    this.heightPx = 0,
    this.durationSeconds,
    this.note,
    this.isCover = false,
    this.isDemo = true,
  });

  /// Deterministic checksum for a seeded item: SHA-256 of id + timestamp.
  static String checksumFor(String id, DateTime takenAt) {
    final bytes = utf8.encode('$id|${takenAt.toIso8601String()}');
    return sha256.convert(bytes).toString();
  }

  /// Rebuilds an item from stored JSON.
  factory MemoryItem.fromJson(Map<String, Object?> json) => MemoryItem(
        id: json['id'] as String,
        kind: MediaKind.values.byName(json['kind'] as String),
        title: json['title'] as String,
        takenAt: DateTime.parse(json['takenAt'] as String),
        checksum: json['checksum'] as String,
        storyId: json['storyId'] as String?,
        chapterId: json['chapterId'] as String?,
        tags: (json['tags'] as List<dynamic>).cast<String>(),
        personIds: (json['personIds'] as List<dynamic>).cast<String>(),
        placeId: json['placeId'] as String?,
        aspectRatio: json['aspectRatio'] as String? ?? '4:3',
        widthPx: json['widthPx'] as int? ?? 0,
        heightPx: json['heightPx'] as int? ?? 0,
        durationSeconds: json['durationSeconds'] as int?,
        note: json['note'] as String?,
        isCover: json['isCover'] as bool? ?? false,
        isDemo: json['isDemo'] as bool? ?? true,
      );

  /// Stable id, e.g. `frame-042`.
  final String id;

  /// What kind of media this is.
  final MediaKind kind;

  /// Display title, e.g. "Frame 042" or "First sketch".
  final String title;

  /// When the moment happened (capture time, not import time).
  final DateTime takenAt;

  /// SHA-256 checksum identifying the source.
  final String checksum;

  /// Story this memory belongs to, if any.
  final String? storyId;

  /// Chapter within the story, if placed.
  final String? chapterId;

  /// Editable tags, e.g. `golden hour`, `deck`, `rain`.
  final List<String> tags;

  /// People in the memory, by person id.
  final List<String> personIds;

  /// Place this memory was taken, by place id.
  final String? placeId;

  /// Aspect ratio label: `1.85:1`, `2.39:1`, `4:3` or `1:1`.
  final String aspectRatio;

  /// Pixel dimensions when known (0 when the demo item has none).
  final int widthPx;

  /// Pixel height when known.
  final int heightPx;

  /// Length in seconds for videos and voice notes.
  final int? durationSeconds;

  /// The editable caption — the top layer of the palimpsest.
  final String? note;

  /// True when this item is the cover frame of its story or chapter.
  final bool isCover;

  /// True for seeded demo-library content.
  final bool isDemo;

  /// Serializes the item for local storage.
  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'kind': kind.name,
        'title': title,
        'takenAt': takenAt.toIso8601String(),
        'checksum': checksum,
        'storyId': storyId,
        'chapterId': chapterId,
        'tags': tags,
        'personIds': personIds,
        'placeId': placeId,
        'aspectRatio': aspectRatio,
        'widthPx': widthPx,
        'heightPx': heightPx,
        'durationSeconds': durationSeconds,
        'note': note,
        'isCover': isCover,
        'isDemo': isDemo,
      };

  /// Returns a copy with the given fields replaced.
  MemoryItem copyWith({
    String? title,
    String? storyId,
    String? chapterId,
    List<String>? tags,
    List<String>? personIds,
    String? placeId,
    String? note,
    bool? isCover,
  }) =>
      MemoryItem(
        id: id,
        kind: kind,
        title: title ?? this.title,
        takenAt: takenAt,
        checksum: checksum,
        storyId: storyId ?? this.storyId,
        chapterId: chapterId ?? this.chapterId,
        tags: tags ?? this.tags,
        personIds: personIds ?? this.personIds,
        placeId: placeId ?? this.placeId,
        aspectRatio: aspectRatio,
        widthPx: widthPx,
        heightPx: heightPx,
        durationSeconds: durationSeconds,
        note: note ?? this.note,
        isCover: isCover ?? this.isCover,
        isDemo: isDemo,
      );
}
