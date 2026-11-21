import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../engine/timeline.dart';
import '../models/memory_item.dart';
import '../widgets/app_shell.dart';
import '../widgets/common.dart';
import '../widgets/story_card.dart';

/// Timeline (m10 / w10): 35+ years, four stories, and the photo box
/// waiting to be scanned. Newest first.
class TimelineScreen extends StatelessWidget {
  /// Creates the timeline screen.
  const TimelineScreen({super.key});

  IconData _kindIcon(MediaKind kind) {
    switch (kind) {
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
    final archive = AppScope.of(context).archive;
    return ListenableBuilder(
      listenable: archive,
      builder: (context, _) {
        final years = TimelineBuilder.build(archive.items, archive.stories);
        final body = SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('35+ years, newest first', style: AppTheme.kicker()),
              const SizedBox(height: 6),
              Text(
                'Timeline',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              for (final year in years) ...<Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      '${year.year}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${year.items.length} memories',
                      style: AppTheme.mono(size: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                for (final story in year.stories) ...<Widget>[
                  StoryCard(
                    story: story,
                    onTap: () => Navigator.of(context).pushNamed(
                      Routes.story,
                      arguments: story.id,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                for (final item in year.items.take(6))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: GlassCard(
                      onTap: () => Navigator.of(context).pushNamed(
                        Routes.media,
                        arguments: item.id,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            _kindIcon(item.kind),
                            size: 18,
                            color: Palette.v7.gold,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.title,
                              style:
                                  Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          Text(
                            Format.shortTimestamp(item.takenAt),
                            style: AppTheme.mono(size: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (year.items.length > 6)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      '+ ${year.items.length - 6} more in the library',
                      style: AppTheme.mono(size: 11),
                    ),
                  ),
                const SizedBox(height: 16),
              ],
              GlassCard(
                onTap: () =>
                    Navigator.of(context).pushNamed(Routes.import),
                borderColor: Palette.v7.gold.withValues(alpha: 0.5),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.photo_library_outlined,
                      color: V7Colors.gold,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'The photo box',
                            style:
                                Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Prints waiting to be scanned — the past, '
                            'still in a box.',
                            style: AppTheme.mono(size: 11),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: V7Colors.muted,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
        return ResponsiveScaffold(
          title: 'Timeline',
          tabIndex: 3,
          mobile: body,
          wide: body,
        );
      },
    );
  }
}
