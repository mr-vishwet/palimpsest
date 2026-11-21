import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/story.dart';
import 'common.dart';

/// Gradient art per story key. The V7 screens use layered SVG art;
/// v0.1 renders deterministic gradients + an icon per story until real
/// thumbnails land (phase 2).
class StoryArt {
  /// Creates story art.
  const StoryArt._();

  /// Gradient colours for a [Story.coverArt] key.
  static List<Color> gradientFor(String key) {
    switch (key) {
      case 'cruise':
        return const <Color>[Color(0xFF1E3A5F), Color(0xFF2D6A8F), Color(0xFFD4A853)];
      case 'moto':
        return const <Color>[Color(0xFF3B2F2F), Color(0xFF7A4A21), Color(0xFFF59E0B)];
      case 'family':
        return const <Color>[Color(0xFF0F766E), Color(0xFF14B8A6), Color(0xFFFDE68A)];
      case 'childhood':
        return const <Color>[Color(0xFF4C1D95), Color(0xFF7C3AED), Color(0xFFF472B6)];
      case 'moment':
      default:
        return const <Color>[Color(0xFF422006), Color(0xFF92400E), Color(0xFFF59E0B)];
    }
  }

  /// Icon for a [Story.coverArt] key.
  static IconData iconFor(String key) {
    switch (key) {
      case 'cruise':
        return Icons.sailing;
      case 'moto':
        return Icons.two_wheeler;
      case 'family':
        return Icons.beach_access;
      case 'childhood':
        return Icons.home;
      case 'moment':
      default:
        return Icons.auto_awesome;
    }
  }
}

/// A story row/card: gradient art, title, place, counts, play time.
class StoryCard extends StatelessWidget {
  /// Creates a story card.
  const StoryCard({required this.story, required this.onTap, super.key});

  /// The story to show.
  final Story story;

  /// Tap handler (opens the story detail).
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const palette = Palette.v7;
    return GlassCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Row(
        children: <Widget>[
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: StoryArt.gradientFor(story.coverArt),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
            ),
            child: Icon(
              StoryArt.iconFor(story.coverArt),
              size: 36,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    story.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${story.place} · ${story.durationLabel}',
                    style: AppTheme.mono(size: 12),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${Format.mediaCounts(photos: story.photoCount, videos: story.videoCount)} · ${Format.duration(story.playSeconds)}',
                    style: AppTheme.mono(size: 11, color: palette.parchment),
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.chevron_right, color: V7Colors.muted),
          ),
        ],
      ),
    );
  }
}
