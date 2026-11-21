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
abstract final class Exporter {
  /// Manifest format version.
  static const int manifestVersion = 1;

  /// Exports a story as a deterministic JSON manifest.
  static String manifestForStory(
    Story story,
    List<MemoryItem> items,
    List<MemoryLayer> layers,
  ) {
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
      'items': storyItems.map(_itemEntry).toList(),
      'layers': storyLayers.map(_layerEntry).toList(),
    });
  }

  /// Exports a reconstructed moment as a deterministic JSON manifest.
  static String manifestForMoment(
    ReconstructedMoment moment,
    List<MemoryItem> items,
  ) {
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
      'items': momentItems.map(_itemEntry).toList(),
      'reasons': <String, String>{
        for (final item in momentItems) item.id: moment.reasonFor(item.id),
      },
    });
  }

  static Map<String, Object?> _itemEntry(MemoryItem item) =>
      <String, Object?>{
        'checksum': item.checksum,
        'id': item.id,
        'kind': item.kind.name,
        'takenAt': item.takenAt.toIso8601String(),
        'tags': List<String>.of(item.tags)..sort(),
        'title': item.title,
      };

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
