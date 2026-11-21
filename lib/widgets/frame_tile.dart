import 'package:material_ui/material_ui.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/memory_item.dart';

/// A frame in the cutting-room grid.
///
/// v0.1 has no real photo bytes — the tile renders a deterministic
/// gradient from the item id, the kind icon, and the frame's metadata
/// (ratio, capture time). Real thumbnails are a phase-2 item; the
/// tile's layout is the one thumbnails will fill.
class FrameTile extends StatelessWidget {
  /// Creates a frame tile.
  const FrameTile({required this.item, required this.onTap, super.key});

  /// The memory to show.
  final MemoryItem item;

  /// Tap handler (opens the media detail).
  final VoidCallback onTap;

  /// Deterministic gradient for an item id.
  static List<Color> gradientFor(String id) {
    var hash = 0;
    for (final unit in id.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    const palettes = <List<Color>>[
      <Color>[Color(0xFF1E3A5F), Color(0xFF2D6A8F)],
      <Color>[Color(0xFF3B2F2F), Color(0xFF7A4A21)],
      <Color>[Color(0xFF0F766E), Color(0xFF14B8A6)],
      <Color>[Color(0xFF4C1D95), Color(0xFF7C3AED)],
      <Color>[Color(0xFF422006), Color(0xFF92400E)],
      <Color>[Color(0xFF831843), Color(0xFFBE185D)],
    ];
    return palettes[hash % palettes.length];
  }

  IconData _kindIcon() {
    switch (item.kind) {
      case MediaKind.photo:
        return Icons.photo_outlined;
      case MediaKind.video:
        return Icons.play_circle_outline;
      case MediaKind.voiceNote:
        return Icons.mic_outlined;
      case MediaKind.note:
        return Icons.note_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    const palette = Palette.v7;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientFor(item.id),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: item.isCover
                ? palette.gold.withValues(alpha: 0.8)
                : palette.hairline,
          ),
        ),
        child: Stack(
          children: <Widget>[
            Center(
              child: Icon(
                _kindIcon(),
                size: 30,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
            Positioned(
              left: 8,
              top: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.aspectRatio,
                  style: AppTheme.mono(size: 10, color: Colors.white),
                ),
              ),
            ),
            if (item.isCover)
              const Positioned(
                right: 8,
                top: 8,
                child: Icon(Icons.star, size: 16, color: Color(0xFFFDE68A)),
              ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.title,
                    style: AppTheme.mono(size: 11, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    Format.shortTimestamp(item.takenAt),
                    style: AppTheme.mono(
                      size: 10,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
