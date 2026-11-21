import 'package:flutter/material.dart';

import '../core/theme.dart';

/// The memory orb: a glossy gold sphere that bobs and breathes.
///
/// The V7 mascot — the visual centre of the ask flow. It drifts slowly
/// (4s loop) and glows; the reconstructing screen pairs it with the
/// progress ring.
class MemoryOrb extends StatefulWidget {
  /// Creates a memory orb.
  const MemoryOrb({this.size = 100, this.glow = true, super.key});

  /// Orb diameter.
  final double size;

  /// Whether to draw the outer glow.
  final bool glow;

  @override
  State<MemoryOrb> createState() => _MemoryOrbState();
}

class _MemoryOrbState extends State<MemoryOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const palette = Palette.v7;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final bob = (t - 0.5) * 12;
        final scale = 1 + (t - 0.5) * 0.06;
        return Transform.translate(
          offset: Offset(0, bob),
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  center: Alignment(-0.35, -0.4),
                  radius: 1.1,
                  colors: <Color>[
                    Color(0xFFFDE68A),
                    Color(0xFFD4A853),
                    Color(0xFFF59E0B),
                    Color(0xFFB45309),
                  ],
                  stops: <double>[0.0, 0.35, 0.7, 1.0],
                ),
                boxShadow: widget.glow
                    ? <BoxShadow>[
                        BoxShadow(
                          color: palette.amber.withValues(alpha: 0.45),
                          blurRadius: 36,
                          spreadRadius: 6,
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                children: <Widget>[
                  Positioned(
                    left: widget.size * 0.18,
                    top: widget.size * 0.12,
                    child: Container(
                      width: widget.size * 0.3,
                      height: widget.size * 0.18,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(widget.size * 0.15),
                      ),
                    ),
                  ),
                  Center(
                    child: Icon(
                      Icons.layers_outlined,
                      size: widget.size * 0.32,
                      color: palette.onGold.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A circular progress ring with a centre label, used beside the orb
/// while a moment reconstructs.
class ProgressRing extends StatelessWidget {
  /// Creates a progress ring.
  const ProgressRing({
    required this.progress,
    required this.label,
    required this.subLabel,
    this.size = 130,
    super.key,
  });

  /// Progress 0–1.
  final double progress;

  /// Centre label (e.g. "38").
  final String label;

  /// Centre sub-label (e.g. "of 47 photos").
  final String subLabel;

  /// Ring diameter.
  final double size;

  @override
  Widget build(BuildContext context) {
    const palette = Palette.v7;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              backgroundColor: palette.glassStrong,
              valueColor: const AlwaysStoppedAnimation<Color>(V7Colors.gold),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(label, style: Theme.of(context).textTheme.headlineSmall),
              Text(
                subLabel,
                style: AppTheme.mono(size: 11),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
