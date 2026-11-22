import 'package:material_ui/material_ui.dart';

import '../core/format.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../models/ask_result.dart';
import '../widgets/app_shell.dart';
import '../widgets/ask_field.dart';
import '../widgets/common.dart';
import '../widgets/story_card.dart';

/// Home (m01 / w01): ask for a moment, the rebuilt moment, the
/// stories — and the counts, derived from the real archive (0 on a
/// fresh archive). The resurface card is date-driven and only shows
/// when resurfacing is switched on.
class HomeScreen extends StatelessWidget {
  /// Creates the home screen.
  const HomeScreen({super.key});

  void _ask(BuildContext context, String question) {
    final scope = AppScope.of(context);
    scope.ask.start(question);
    Navigator.of(context).pushNamed(
      Routes.reconstructing,
      arguments: question,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'Palimpsest',
      tabIndex: 0,
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => Navigator.of(context).pushNamed(Routes.settings),
          tooltip: 'Settings',
        ),
      ],
      mobile: _HomeBody(onAsk: _ask, wide: false),
      wide: _HomeBody(onAsk: _ask, wide: true),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.onAsk, required this.wide});

  final void Function(BuildContext context, String question) onAsk;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final archive = AppScope.of(context).archive;
    return ListenableBuilder(
      listenable: archive,
      builder: (context, _) {
        final moment = archive.latestMoment;
        final isEmpty = archive.items.isEmpty && archive.stories.isEmpty;
        final hasDemoContent = archive.items.any((i) => i.isDemo) ||
            archive.stories.any((s) => s.isDemo);
        final photos = ArchiveCounts.photos(archive.items);
        final videos = ArchiveCounts.videos(archive.items);
        final resurfaced = archive.settings.resurfaceEnabled
            ? pickResurfacedDay(archive.items, DateTime.now())
            : null;
        final left = <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const StatusPill(label: 'On-device'),
              if (hasDemoContent)
                const StatusPill(
                  label: 'Demo library',
                  dotColor: V7Colors.amber,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Your life, as an editable memory',
            style: AppTheme.kicker(),
          ),
          const SizedBox(height: 6),
          Text(
            'Ask for a moment',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 6),
          Text(
            'One question rebuilds the collection.',
            style: Theme.of(context)
                .textTheme
                .bodyLarge!
                .copyWith(color: Palette.v7.parchment),
          ),
          const SizedBox(height: 16),
          AskField(onAsk: (q) => onAsk(context, q)),
          if (moment != null) ...<Widget>[
            const SizedBox(height: 16),
            _RebuiltMomentCard(moment: moment),
          ],
          const SizedBox(height: 16),
          if (isEmpty)
            _EmptyArchiveCard()
          else if (resurfaced != null)
            _ResurfaceCard(day: resurfaced),
        ];

        final right = <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Stories · ${archive.stories.length}',
                style: AppTheme.kicker(),
              ),
              Text(
                '${Format.count(photos)} photos · '
                '$videos videos',
                style: AppTheme.mono(size: 12, color: Palette.v7.parchment),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (archive.stories.isEmpty)
            const Text(
              'No stories yet — save one from a reconstructed moment, '
              'or import photos to begin.',
              style: TextStyle(color: V7Colors.muted),
            )
          else
            for (final story in archive.stories) ...<Widget>[
              StoryCard(
                story: story,
                onTap: () => Navigator.of(context).pushNamed(
                  Routes.story,
                  arguments: story.id,
                ),
              ),
              const SizedBox(height: 10),
            ],
          const SizedBox(height: 8),
          Text(
            '${Format.count(archive.items.length)} items · '
            '${archive.voiceNotes.length} voice notes · 0 uploaded',
            style: AppTheme.mono(size: 11),
          ),
        ];

        if (wide) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(flex: 5, child: Column(children: left)),
                const SizedBox(width: 24),
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: right,
                  ),
                ),
              ],
            ),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[...left, const SizedBox(height: 20), ...right],
          ),
        );
      },
    );
  }
}

/// The empty-archive welcome: no items and no stories yet, so the
/// honest first step is importing, not a resurfaced memory.
class _EmptyArchiveCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: Palette.v7.gold.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Your archive is empty',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Import photos and videos and they will live here — '
            'searchable, on this device, nothing uploaded.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium!
                .copyWith(color: Palette.v7.parchment),
          ),
          const SizedBox(height: 12),
          GradientButton(
            label: 'Import photos & videos',
            expanded: true,
            onPressed: () => Navigator.of(context).pushNamed(Routes.import),
          ),
        ],
      ),
    );
  }
}

/// The resurface card: one day from a past year, picked from the
/// real archive by date. Only built when there is a day to show and
/// resurfacing is switched on.
class _ResurfaceCard extends StatelessWidget {
  const _ResurfaceCard({required this.day});

  final ResurfacedDay day;

  @override
  Widget build(BuildContext context) {
    final archive = AppScope.of(context).archive;
    final storyId = day.sharedStoryId;
    final story = storyId == null ? null : archive.storyById(storyId);
    final years = day.yearsAgo(DateTime.now());
    final subtitle = <String>[
      if (story != null) story.title else day.items.first.title,
      Format.mediaCounts(photos: day.photos, videos: day.videos),
    ].join(' — ');
    return GlassCard(
      onTap: () => Navigator.of(context).pushNamed(Routes.resurface),
      child: Row(
        children: <Widget>[
          const Icon(Icons.history, color: V7Colors.gold),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '$years ${years == 1 ? 'year' : 'years'} ago this week',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTheme.mono(size: 11)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: V7Colors.muted),
        ],
      ),
    );
  }
}

class _RebuiltMomentCard extends StatelessWidget {
  const _RebuiltMomentCard({required this.moment});

  final ReconstructedMoment moment;

  @override
  Widget build(BuildContext context) {
    const palette = Palette.v7;
    final archive = AppScope.of(context).archive;
    final items =
        moment.visibleItemIds.map(archive.itemById).whereType<Object>().length;
    return GlassCard(
      borderColor: palette.gold.withValues(alpha: 0.6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('Rebuilt just now', style: AppTheme.kicker()),
              Text(
                '$items items',
                style: AppTheme.mono(size: 12, color: palette.parchment),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(moment.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            '“${moment.query}”',
            style: AppTheme.mono(size: 11, color: palette.muted),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: GradientButton(
                  label: 'Open the moment',
                  expanded: true,
                  onPressed: () => Navigator.of(context).pushNamed(
                    Routes.moment,
                    arguments: moment.id,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: moment.savedAsStoryId != null
                      ? () => Navigator.of(context).pushNamed(
                            Routes.story,
                            arguments: moment.savedAsStoryId!,
                          )
                      : () {
                          final storyId = archive.saveMomentAsStory(moment.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Saved as a story'),
                            ),
                          );
                          Navigator.of(context).pushNamed(
                            Routes.story,
                            arguments: storyId,
                          );
                        },
                  child: Text(
                    moment.savedAsStoryId != null
                        ? 'Open the story'
                        : 'Save as story',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
