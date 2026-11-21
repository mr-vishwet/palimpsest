import 'package:flutter/material.dart';

import '../core/theme.dart';

/// A waveform drawn from deterministic bar heights, with a playhead.
///
/// Tapping a bar seeks to that position (the parent owns playback
/// state). Bars behind the playhead render gold; ahead, muted.
class Waveform extends StatelessWidget {
  /// Creates a waveform.
  const Waveform({
    required this.heights,
    required this.progress,
    this.onSeek,
    this.height = 64,
    super.key,
  });

  /// Bar heights, 0–1.
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
