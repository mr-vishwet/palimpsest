import 'package:collection/collection.dart';
import 'package:material_ui/material_ui.dart';

import '../core/format.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/common.dart';
import '../widgets/frame_tile.dart';

/// Resurface (m18 / w18): this week in past years — one day picked
/// from the real archive by date, never a hardcoded memory. When
/// nothing from a past year falls in this week, the screen says so.
class ResurfaceScreen extends StatelessWidget {
  /// Creates the resurface screen.
  const ResurfaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final archive = AppScope.of(context).archive;
    return ListenableBuilder(
      listenable: archive,
      builder: (context, _) {
        final now = DateTime.now();
        final day = pickResurfacedDay(archive.items, now);
        final settings = archive.settings;
        final story = day?.sharedStoryId == null
            ? null
            : archive.storyById(day!.sharedStoryId!);
        final chapter = story?.chapters
            .where((c) => c.id == day?.sharedChapterId)
            .firstOrNull;

        final body = SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (day == null) ...<Widget>[
                Text('This week in past years', style: AppTheme.kicker()),
                const SizedBox(height: 6),
                Text(
                  'Resurface',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                const EmptyState(
                  icon: Icons.history,
                  title: 'Nothing to resurface this week',
                  body: 'When past years hold memories from this week, '
                      'they will appear here — one day, in full.',
                ),
              ] else ...<Widget>[
                Text(
                  '${day.yearsAgo(now)} ${day.yearsAgo(now) == 1 ? 'year' : 'years'} ago this week',
                  style: AppTheme.kicker(),
                ),
                const SizedBox(height: 6),
                Text(
                  chapter?.title ?? story?.title ?? day.items.first.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  <String>[
                    if (story != null) story.title,
                    if (chapter != null && chapter.day > 0)
                      'day ${chapter.day}',
                    Format.mediaCounts(
                      photos: day.photos,
                      videos: day.videos,
                    ),
                    if (day.peopleCount > 0)
                      '${day.peopleCount} '
                          '${day.peopleCount == 1 ? 'person' : 'people'}',
                  ].join(' · '),
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
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: day.items.length,
                  itemBuilder: (context, i) => FrameTile(
                    item: day.items[i],
                    onTap: () => Navigator.of(context).pushNamed(
                      Routes.media,
                      arguments: day.items[i].id,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (story != null)
                  GradientButton(
                    label: 'Open ${story.title}',
                    expanded: true,
                    onPressed: () => Navigator.of(context).pushNamed(
                      Routes.story,
                      arguments: story.id,
                    ),
                  ),
              ],
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
              const SizedBox(height: 6),
              Text(
                'Switching this off hides the resurface card on Home.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall!
                    .copyWith(color: Palette.v7.muted),
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
