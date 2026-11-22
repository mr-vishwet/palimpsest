import 'package:collection/collection.dart';

/// What a layer changed on a memory.
enum LayerKind {
  /// The caption (note) text.
  caption,

  /// The tag set.
  tags,

  /// The people attached.
  people,

  /// The cover-frame choice.
  cover,

  /// The title.
  title,
}

/// One layer of the palimpsest: a single edit to a memory.
///
/// The metaphor is the product: nothing is ever overwritten. Every edit
/// writes a new layer on top, and the older layers stay visible beneath
/// — the layer history on the media detail screen shows each layer with
/// its previous value, so any edit can be understood and reverted.
class MemoryLayer {
  /// Creates a layer.
  const MemoryLayer({
    required this.id,
    required this.memoryId,
    required this.kind,
    required this.summary,
    required this.previousValue,
    required this.newValue,
    required this.createdAt,
    this.author = 'You',
    this.isDemo = false,
  });

  /// Rebuilds a layer from stored JSON.
  factory MemoryLayer.fromJson(Map<String, Object?> json) => MemoryLayer(
        id: json['id'] as String,
        memoryId: json['memoryId'] as String,
        kind: LayerKind.values.byName(json['kind'] as String),
        summary: json['summary'] as String,
        previousValue: json['previousValue'] as String,
        newValue: json['newValue'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        author: json['author'] as String? ?? 'You',
        isDemo: json['isDemo'] as bool? ?? false,
      );

  /// Stable id, e.g. `layer-frame-042-1`.
  final String id;

  /// The memory this layer belongs to.
  final String memoryId;

  /// What the layer changed.
  final LayerKind kind;

  /// Human-readable summary, e.g. "Caption changed".
  final String summary;

  /// The value before this layer (empty string when there was none).
  final String previousValue;

  /// The value after this layer.
  final String newValue;

  /// When the layer was written.
  final DateTime createdAt;

  /// Who wrote the layer.
  final String author;

  /// True for demo-media content (loaded from the bundled demo set).
  /// Real imports and user-created content are false.
  final bool isDemo;

  /// Serializes the layer for local storage.
  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'memoryId': memoryId,
        'kind': kind.name,
        'summary': summary,
        'previousValue': previousValue,
        'newValue': newValue,
        'createdAt': createdAt.toIso8601String(),
        'author': author,
        'isDemo': isDemo,
      };
}

/// Pure operations over a memory's layer stack.
///
/// The current value of any field is the newest layer of that kind, or
/// the stored fallback when no layer exists. Reverting removes the
/// newest layer of a kind, revealing the value beneath — it never
/// deletes history, it only peels the top layer off.
abstract final class LayerStack {
  /// Layers for one memory, newest first.
  static List<MemoryLayer> forMemory(
    List<MemoryLayer> all,
    String memoryId,
  ) {
    final mine =
        all.where((layer) => layer.memoryId == memoryId).toList(growable: false);
    mine.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return mine;
  }

  /// The current value of [kind] for a memory: the newest layer's
  /// [MemoryLayer.newValue], or [fallback] when no layer exists.
  static String currentValue(
    List<MemoryLayer> layers,
    LayerKind kind,
    String fallback,
  ) {
    for (final layer in layers) {
      if (layer.kind == kind) {
        return layer.newValue;
      }
    }
    return fallback;
  }

  /// The newest layer of [kind], or null when the field was never edited.
  static MemoryLayer? latestOfKind(List<MemoryLayer> layers, LayerKind kind) {
    for (final layer in layers) {
      if (layer.kind == kind) {
        return layer;
      }
    }
    return null;
  }

  /// Reverts [layerId]: returns the stack with that layer removed.
  ///
  /// Only the newest layer of its kind may be reverted — reverting a
  /// buried layer would rewrite history. Returns the unchanged list
  /// when the layer is not the newest of its kind.
  static List<MemoryLayer> revert(
    List<MemoryLayer> layers,
    String layerId,
  ) {
    final target = layers.where((layer) => layer.id == layerId).firstOrNull;
    if (target == null) {
      return layers;
    }
    if (latestOfKind(layers, target.kind)?.id != layerId) {
      return layers;
    }
    return layers.where((layer) => layer.id != layerId).toList(growable: false);
  }
}
