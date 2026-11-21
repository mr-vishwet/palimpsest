import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../core/routes.dart';
import '../core/theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/common.dart';
import '../widgets/frame_tile.dart';

/// Resurface (m18 / w18): three years ago this week — the day it
/// rained in Hawaii. 31 photos · 2 videos · 5 people.
class ResurfaceScreen extends StatelessWidget {
  /// Creates the resurface screen.
  const ResurfaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final archive = AppScope.of(context).archive;
    return ListenableBuilder(
      listenable: archive,
      builder: (context, _) {
        final story = archive.storyById('family');
        final chapter = story?.chapters
            .where((c) => c.id == 'family-ch3')
            .firstOrNull;
        final items = archive.items
            .where((item) => item.chapterId == 'family-ch3')
            .toList(growable: false);
        final settings = archive.settings;

        final body = SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Three years ago this week', style: AppTheme.kicker()),
              const SizedBox(height: 6),
              Text(
                'The day it rained in Hawaii',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                'Family Vacation · day 4 · 31 photos · 2 videos · 5 people',
                style: AppTheme.mono(size: 12, color: Palette.v7.parchment),
              ),
              const SizedBox(height: 16),
              if (chapter != null && chapter.caption.isNotEmpty)
                GlassCard(
                  child: Text(
                    '“${chapter.caption}”',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              const SizedBox(height: 16),
              if (items.isEmpty)
                const Text(
                  'No frames from that day in the demo subset.',
                  style: TextStyle(color: V7Colors.muted),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, i) => FrameTile(
                    item: items[i],
                    onTap: () => Navigator.of(context).pushNamed(
                      Routes.media,
                      arguments: items[i].id,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              if (story != null)
                GradientButton(
                  label: 'Open Family Vacation',
                  expanded: true,
                  onPressed: () => Navigator.of(context).pushNamed(
                    Routes.story,
                    arguments: story.id,
                  ),
                ),
              const SizedBox(height: 16),
              GlassCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Expanded(
                      child: Text('Resurface moments like this'),
                    ),
                    Switch(
                      value: settings.resurfaceEnabled,
                      onChanged: (value) => archive.updateSettings(
                        settings.copyWith(resurfaceEnabled: value),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
        return ResponsiveScaffold(
          title: 'Resurface',
          tabIndex: 0,
          mobile: body,
          wide: body,
        );
      },
    );
  }
}
