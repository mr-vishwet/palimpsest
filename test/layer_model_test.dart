import 'package:flutter_test/flutter_test.dart';
import 'package:palimpsest/models/layer.dart';

void main() {
  group('LayerStack', () {
    final layers = <MemoryLayer>[
      MemoryLayer(
        id: 'l1',
        memoryId: 'frame-042',
        kind: LayerKind.caption,
        summary: 'Caption changed',
        previousValue: '',
        newValue: 'First caption.',
        createdAt: DateTime(2025, 6, 20, 10, 15),
      ),
      MemoryLayer(
        id: 'l2',
        memoryId: 'frame-042',
        kind: LayerKind.caption,
        summary: 'Caption changed',
        previousValue: 'First caption.',
        newValue: 'Opening frame — boarding at dusk.',
        createdAt: DateTime(2025, 6, 21, 9, 2),
      ),
      MemoryLayer(
        id: 'l3',
        memoryId: 'frame-042',
        kind: LayerKind.tags,
        summary: 'Tags added',
        previousValue: 'golden hour',
        newValue: 'golden hour, deck',
        createdAt: DateTime(2025, 6, 22, 11, 0),
      ),
      MemoryLayer(
        id: 'l4',
        memoryId: 'other',
        kind: LayerKind.caption,
        summary: 'Caption changed',
        previousValue: '',
        newValue: 'Elsewhere.',
        createdAt: DateTime(2025, 6, 23, 11, 0),
      ),
    ];

    test('forMemory returns newest first, only for that memory', () {
      final mine = LayerStack.forMemory(layers, 'frame-042');
      expect(mine.map((l) => l.id), ['l3', 'l2', 'l1']);
    });

    test('currentValue is the newest layer of that kind', () {
      final mine = LayerStack.forMemory(layers, 'frame-042');
      expect(
        LayerStack.currentValue(mine, LayerKind.caption, 'fallback'),
        'Opening frame — boarding at dusk.',
      );
      expect(
        LayerStack.currentValue(mine, LayerKind.tags, 'fallback'),
        'golden hour, deck',
      );
    });

    test('currentValue falls back when no layer exists', () {
      final mine = LayerStack.forMemory(layers, 'frame-042');
      expect(
        LayerStack.currentValue(mine, LayerKind.cover, 'Frame 041'),
        'Frame 041',
      );
    });

    test('latestOfKind finds the newest layer of a kind', () {
      final mine = LayerStack.forMemory(layers, 'frame-042');
      expect(LayerStack.latestOfKind(mine, LayerKind.caption)?.id, 'l2');
      expect(LayerStack.latestOfKind(mine, LayerKind.cover), isNull);
    });

    test('revert removes only the newest layer of its kind', () {
      final mine = LayerStack.forMemory(layers, 'frame-042');
      final reverted = LayerStack.revert(mine, 'l2');
      expect(reverted.map((l) => l.id), ['l3', 'l1']);
      // The value beneath is revealed.
      expect(
        LayerStack.currentValue(reverted, LayerKind.caption, 'fallback'),
        'First caption.',
      );
    });

    test('revert of a buried layer is a no-op', () {
      final mine = LayerStack.forMemory(layers, 'frame-042');
      final reverted = LayerStack.revert(mine, 'l1');
      expect(reverted.map((l) => l.id), ['l3', 'l2', 'l1']);
    });

    test('revert of an unknown layer is a no-op', () {
      final mine = LayerStack.forMemory(layers, 'frame-042');
      final reverted = LayerStack.revert(mine, 'nope');
      expect(reverted, hasLength(3));
    });
  });
}
