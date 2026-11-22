import 'dart:convert';

import '../models/ask_result.dart';
import '../models/layer.dart';
import '../models/memory_item.dart';
import '../models/story.dart';

/// Deterministic export: re-exporting the same collection produces
/// identical bytes.
///
/// The manifest is the provenance record — every item carries its id,
/// checksum and capture time, and every layer is listed so the edit
/// history travels with the export. Keys are written in a fixed order
/// and lists are sorted before encoding, so the output depends only
/// on the data, never on insertion order or map iteration.
///
/// Version 2 adds per-item `file` entries when the export carries
/// media: each entry names the file inside the export zip and repeats
/// its SHA-256, so the manifest alone proves which bytes belong to
/// which memory. Without media the manifest is unchanged apart from
/// the version number.
abstract final class Exporter {
  /// Manifest format version.
  static const int manifestVersion = 2;

  /// Exports a story as a deterministic JSON manifest.
  ///
  /// Pass [mediaFiles] (keyed by item id) when the export carries the
  /// real media bytes — each item then gains a `file` entry naming
  /// its file in the zip. Items without an entry export
  /// metadata-only, exactly as before.
  static String manifestForStory(
    Story story,
    List<MemoryItem> items,
    List<MemoryLayer> layers, {
    Map<String, ExportMediaFile>? mediaFiles,
  }) {
    final storyItems =
        items.where((item) => item.storyId == story.id).toList(growable: false)
          ..sort((a, b) => a.id.compareTo(b.id));
    final storyLayers = layers
        .where((layer) => storyItems.any((item) => item.id == layer.memoryId))
        .toList(growable: false)
      ..sort((a, b) {
        final byTime = a.createdAt.compareTo(b.createdAt);
        return byTime != 0 ? byTime : a.id.compareTo(b.id);
      });
    return _encode(<String, Object?>{
      'format': 'palimpsest-manifest',
      'version': manifestVersion,
      'kind': 'story',
      'id': story.id,
      'title': story.title,
      'place': story.place,
      'chapters': story.orderedChapters
          .map((c) => <String, Object?>{
                'id': c.id,
                'order': c.order,
                'title': c.title,
                'caption': c.caption,
                'day': c.day,
              })
          .toList(),
      'items': storyItems.map((i) => _itemEntry(i, mediaFiles)).toList(),
      'layers': storyLayers.map(_layerEntry).toList(),
    });
  }

  /// Exports a reconstructed moment as a deterministic JSON manifest.
  ///
  /// Pass [mediaFiles] (keyed by item id) when the export carries the
  /// real media bytes — see [manifestForStory].
  static String manifestForMoment(
    ReconstructedMoment moment,
    List<MemoryItem> items, {
    Map<String, ExportMediaFile>? mediaFiles,
  }) {
    final momentItems = items
        .where((item) => moment.visibleItemIds.contains(item.id))
        .toList(growable: false)
      ..sort((a, b) => a.id.compareTo(b.id));
    return _encode(<String, Object?>{
      'format': 'palimpsest-manifest',
      'version': manifestVersion,
      'kind': 'moment',
      'id': moment.id,
      'query': moment.query,
      'title': moment.title,
      'rebuiltMs': moment.rebuildMs,
      'items': momentItems.map((i) => _itemEntry(i, mediaFiles)).toList(),
      'reasons': <String, String>{
        for (final item in momentItems) item.id: moment.reasonFor(item.id),
      },
    });
  }

  static Map<String, Object?> _itemEntry(
    MemoryItem item,
    Map<String, ExportMediaFile>? mediaFiles,
  ) {
    final entry = <String, Object?>{
      'checksum': item.checksum,
      'id': item.id,
      'kind': item.kind.name,
      'takenAt': item.takenAt.toIso8601String(),
      'tags': List<String>.of(item.tags)..sort(),
      'title': item.title,
    };
    final file = mediaFiles?[item.id];
    if (file != null) {
      entry['file'] = file.toJson();
    }
    return entry;
  }

  static Map<String, Object?> _layerEntry(MemoryLayer layer) =>
      <String, Object?>{
        'createdAt': layer.createdAt.toIso8601String(),
        'id': layer.id,
        'kind': layer.kind.name,
        'memoryId': layer.memoryId,
        'newValue': layer.newValue,
        'previousValue': layer.previousValue,
      };

  static String _encode(Map<String, Object?> manifest) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(manifest);
  }
}

/// One media file carried inside an export zip, referenced from the
/// manifest by item id.
///
/// The `fileName` is the file's path inside the zip; `sha256` repeats
/// the item checksum so the manifest alone proves the bytes belong to
/// the memory they are filed under.
class ExportMediaFile {
  /// Creates a media file entry.
  const ExportMediaFile({
    required this.fileName,
    required this.byteSize,
    required this.sha256,
  });

  /// Path inside the zip, e.g. `media/frame-042.jpg`.
  final String fileName;

  /// Size of the file in bytes.
  final int byteSize;

  /// SHA-256 of the file bytes (the item's checksum).
  final String sha256;

  /// Serializes the entry for the manifest.
  Map<String, Object?> toJson() => <String, Object?>{
        'byteSize': byteSize,
        'fileName': fileName,
        'sha256': sha256,
      };
}
