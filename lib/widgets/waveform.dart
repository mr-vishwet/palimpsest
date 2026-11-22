import 'package:material_ui/material_ui.dart';

import '../core/theme.dart';

/// A waveform drawn from real peak heights, with a playhead.
///
/// Tapping a bar seeks to that position (the parent owns playback
/// state). Bars behind the playhead render gold; ahead, muted. An
/// empty heights list means the note has no audio to draw — the
/// widget says so instead of inventing bars.
class Waveform extends StatelessWidget {
  /// Creates a waveform.
  const Waveform({
    required this.heights,
    required this.progress,
    this.onSeek,
    this.height = 64,
    super.key,
  });

  /// Bar heights, 0–1, computed from the recorded audio. Empty when
  /// the note has no audio.
  final List<double> heights;

  /// Playback progress, 0–1.
  final double progress;

  /// Seek handler, called with the new progress 0–1.
  final void Function(double progress)? onSeek;

  /// Waveform height.
  final double height;

  @override
  Widget build(BuildContext context) {
    const palette = Palette.v7;
    if (heights.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'No waveform — this note has no recording',
            style: AppTheme.mono(size: 11, color: palette.muted),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return GestureDetector(
      onTapDown: onSeek == null
          ? null
          : (details) {
              final box = context.findRenderObject()! as RenderBox;
              final local = box.globalToLocal(details.globalPosition);
              final next = (local.dx / box.size.width).clamp(0, 1).toDouble();
              onSeek!(next);
            },
      child: SizedBox(
        height: height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            for (var i = 0; i < heights.length; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Container(
                    height: (heights[i] * height).clamp(4, height).toDouble(),
                    decoration: BoxDecoration(
                      color: i / heights.length <= progress
                          ? palette.gold
                          : palette.muted.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
