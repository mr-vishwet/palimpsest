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
/// the item it came from. Imported items hash the file bytes; the
/// original bytes live in the blob store under [blobId] and the
/// thumbnail under [thumbBlobId].
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
    this.isDemo = false,
    this.blobId,
    this.thumbBlobId,
    this.mimeType,
    this.sourceName,
    this.gpsLat,
    this.gpsLng,
  });

  /// SHA-256 checksum of file bytes, for imported items.
  static String checksumOfBytes(List<int> bytes) =>
      sha256.convert(bytes).toString();

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
        isDemo: json['isDemo'] as bool? ?? false,
        blobId: json['blobId'] as String?,
        thumbBlobId: json['thumbBlobId'] as String?,
        mimeType: json['mimeType'] as String?,
        sourceName: json['sourceName'] as String?,
        gpsLat: (json['gpsLat'] as num?)?.toDouble(),
        gpsLng: (json['gpsLng'] as num?)?.toDouble(),
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

  /// True for demo-media content (loaded from the bundled demo set).
  /// Real imports and user-created content are false.
  final bool isDemo;

  /// Key of the original file bytes in the blob store, if imported.
  final String? blobId;

  /// Key of the thumbnail bytes in the blob store, if one was made.
  final String? thumbBlobId;

  /// MIME type of the original file, e.g. `image/jpeg`.
  final String? mimeType;

  /// Original filename at import, e.g. `IMG_0421.jpg`.
  final String? sourceName;

  /// GPS latitude from EXIF, when the file carried one.
  final double? gpsLat;

  /// GPS longitude from EXIF, when the file carried one.
  final double? gpsLng;

  /// True when this item has real bytes behind it (an import).
  bool get hasBytes => blobId != null;

  /// Returns a copy detached from its story and chapter (used by the
  /// v1 migration when the item's story was dropped as demo content).
  MemoryItem withoutStory() => MemoryItem(
        id: id,
        kind: kind,
        title: title,
        takenAt: takenAt,
        checksum: checksum,
        tags: tags,
        personIds: personIds,
        placeId: placeId,
        aspectRatio: aspectRatio,
        widthPx: widthPx,
        heightPx: heightPx,
        durationSeconds: durationSeconds,
        note: note,
        isCover: false,
        isDemo: isDemo,
        blobId: blobId,
        thumbBlobId: thumbBlobId,
        mimeType: mimeType,
        sourceName: sourceName,
        gpsLat: gpsLat,
        gpsLng: gpsLng,
      );

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
        'blobId': blobId,
        'thumbBlobId': thumbBlobId,
        'mimeType': mimeType,
        'sourceName': sourceName,
        'gpsLat': gpsLat,
        'gpsLng': gpsLng,
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
    int? widthPx,
    int? heightPx,
    int? durationSeconds,
    String? aspectRatio,
    String? blobId,
    String? thumbBlobId,
    String? mimeType,
    String? sourceName,
    double? gpsLat,
    double? gpsLng,
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
        aspectRatio: aspectRatio ?? this.aspectRatio,
        widthPx: widthPx ?? this.widthPx,
        heightPx: heightPx ?? this.heightPx,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        note: note ?? this.note,
        isCover: isCover ?? this.isCover,
        isDemo: isDemo,
        blobId: blobId ?? this.blobId,
        thumbBlobId: thumbBlobId ?? this.thumbBlobId,
        mimeType: mimeType ?? this.mimeType,
        sourceName: sourceName ?? this.sourceName,
        gpsLat: gpsLat ?? this.gpsLat,
        gpsLng: gpsLng ?? this.gpsLng,
      );
}
