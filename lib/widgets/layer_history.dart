import 'package:material_ui/material_ui.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/layer.dart';
import 'common.dart';

/// The layer history of a memory: every edit, newest first, with the
/// previous value visible beneath — the palimpsest made literal.
///
/// Only the newest layer of each kind can be reverted (peeling a
/// buried layer would rewrite history); the revert button appears
/// only on those layers.
class LayerHistory extends StatelessWidget {
  /// Creates a layer history list.
  const LayerHistory({
    required this.layers,
    required this.onRevert,
    super.key,
  });

  /// Layers for the memory, newest first.
  final List<MemoryLayer> layers;

  /// Called with the layer id when the user reverts a layer.
  final void Function(String layerId) onRevert;

  IconData _kindIcon(LayerKind kind) {
    switch (kind) {
      case LayerKind.caption:
        return Icons.edit_outlined;
      case LayerKind.tags:
        return Icons.label_outlined;
      case LayerKind.people:
        return Icons.person_outline;
      case LayerKind.cover:
        return Icons.star_outline;
      case LayerKind.title:
        return Icons.title;
    }
  }

  @override
  Widget build(BuildContext context) {
    const palette = Palette.v7;
    if (layers.isEmpty) {
      return const Text(
        'No edits yet — the first layer is the original.',
        style: TextStyle(color: V7Colors.muted),
      );
    }
    return Column(
      children: <Widget>[
        for (final layer in layers)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GlassCard(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    _kindIcon(layer.kind),
                    size: 20,
                    color: palette.gold,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              layer.summary,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              Format.shortTimestamp(layer.createdAt),
                              style: AppTheme.mono(size: 11),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (layer.previousValue.isNotEmpty)
                          Text(
                            'Before: ${layer.previousValue}',
                            style: AppTheme.mono(
                              size: 11,
                              color: palette.muted,
                            ),
                          ),
                        Text(
                          'Now: ${layer.newValue}',
                          style: AppTheme.mono(size: 11, color: palette.parchment),
                        ),
                      ],
                    ),
                  ),
                  if (LayerStack.latestOfKind(layers, layer.kind)?.id ==
                      layer.id)
                    TextButton(
                      onPressed: () => onRevert(layer.id),
                      child: const Text('Revert'),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
