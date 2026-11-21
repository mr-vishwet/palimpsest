import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../core/format.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../engine/exporter.dart';
import '../widgets/app_shell.dart';
import '../widgets/common.dart';
import '../widgets/story_card.dart';

/// Story detail (m02 / w02): chapters, counts, play time, play and
/// share. Chapters carry their own play times; the story total is the
/// sum of its chapters.
class StoryDetailScreen extends StatefulWidget {
  /// Creates the story detail screen.
  const StoryDetailScreen({required this.storyId, super.key});

  /// The story to show.
  final String storyId;

  @override
  State<StoryDetailScreen> createState() => _StoryDetailScreenState();
}

class _StoryDetailScreenState extends State<StoryDetailScreen> {
  Timer? _playTimer;
  int _playingChapter = -1;
  double _chapterProgress = 0;

  @override
  void dispose() {
    _playTimer?.cancel();
    super.dispose();
  }

  void _togglePlay(int chapterCount) {
    if (_playingChapter >= 0) {
      _playTimer?.cancel();
      setState(() {
        _playingChapter = -1;
        _chapterProgress = 0;
      });
      return;
    }
    setState(() {
      _playingChapter = 0;
      _chapterProgress = 0;
    });
    // A chapter plays over ~6 seconds in the demo player (the real
    // player renders the frames; v0.1 steps through chapters).
    _playTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _chapterProgress += 100 / 6000;
        if (_chapterProgress >= 1) {
          _chapterProgress = 0;
          _playingChapter++;
          if (_playingChapter >= chapterCount) {
            timer.cancel();
            _playingChapter = -1;
          }
        }
      });
    });
  }

  void _share(BuildContext context) {
    final scope = AppScope.of(context);
    if (!scope.auth.isSignedIn) {
      Navigator.of(context).pushNamed(Routes.upgrade, arguments: widget.storyId);
      return;
    }
    Navigator.of(context).pushNamed(Routes.share, arguments: widget.storyId);
  }

  void _export(BuildContext context) {
    final archive = AppScope.of(context).archive;
    final story = archive.storyById(widget.storyId);
    if (story == null) {
      return;
    }
    final manifest = Exporter.manifestForStory(
      story,
      archive.items,
      archive.layers,
    );
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export manifest'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(manifest, style: AppTheme.mono(size: 11)),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: manifest));
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Manifest copied')),
              );
            },
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final archive = AppScope.of(context).archive;
    return ListenableBuilder(
      listenable: archive,
      builder: (context, _) {
        final story = archive.storyById(widget.storyId);
        if (story == null) {
          return const ResponsiveScaffold(
            title: 'Story',
            tabIndex: 0,
            mobile: EmptyState(
              icon: Icons.book_outlined,
              title: 'Story not found',
              body: 'This story is no longer in the archive.',
            ),
            wide: EmptyState(
              icon: Icons.book_outlined,
              title: 'Story not found',
              body: 'This story is no longer in the archive.',
            ),
          );
        }
        final chapters = story.orderedChapters;
        final body = SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '${story.place} · ${story.durationLabel}',
                style: AppTheme.kicker(),
              ),
              const SizedBox(height: 6),
              Text(story.title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              Container(
                height: 140,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: StoryArt.gradientFor(story.coverArt),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Icon(
                    StoryArt.iconFor(story.coverArt),
                    size: 56,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(child: StatTile(value: '${story.photoCount}', label: 'photos')),
                  const SizedBox(width: 8),
                  Expanded(child: StatTile(value: '${story.videoCount}', label: 'videos')),
                  const SizedBox(width: 8),
                  Expanded(child: StatTile(value: '${story.days == 0 ? '—' : story.days}', label: 'days')),
                  const SizedBox(width: 8),
                  Expanded(child: StatTile(value: '${story.peopleCount}', label: 'people')),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    'Chapters · ${chapters.length}',
                    style: AppTheme.kicker(),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushNamed(
                      Routes.compose,
                      arguments: story.id,
                    ),
                    child: const Text('Edit order'),
                  ),
                ],
              ),
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: <Widget>[
                    for (var i = 0; i < chapters.length; i++)
                      InkWell(
                        onTap: () => Navigator.of(context).pushNamed(
                          Routes.chapterEdit,
                          arguments: <String, String>{
                            'storyId': story.id,
                            'chapterId': chapters[i].id,
                          },
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: <Widget>[
                              Text(
                                '0${i + 1}',
                                style: AppTheme.mono(size: 13),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      chapters[i].title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall,
                                    ),
                                    Text(
                                      chapters[i].day > 0
                                          ? 'Day ${chapters[i].day} · '
                                              '${Format.mediaCounts(photos: chapters[i].photoCount, videos: chapters[i].videoCount)}'
                                          : Format.mediaCounts(
                                              photos: chapters[i].photoCount,
                                              videos: chapters[i].videoCount,
                                            ),
                                      style: AppTheme.mono(size: 11),
                                    ),
                                    if (chapters[i].caption.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          '“${chapters[i].caption}”',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall!
                                              .copyWith(
                                                color: Palette.v7.parchment,
                                              ),
                                        ),
                                      ),
                                    if (_playingChapter == i)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: LinearProgressIndicator(
                                          value: _chapterProgress,
                                          color: Palette.v7.gold,
                                          backgroundColor:
                                              Palette.v7.glassStrong,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                Format.duration(chapters[i].playSeconds),
                                style: AppTheme.mono(size: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    flex: 3,
                    child: GradientButton(
                      icon: _playingChapter >= 0
                          ? Icons.stop
                          : Icons.play_arrow,
                      label: _playingChapter >= 0
                          ? 'Stop'
                          : 'Play the story · ${Format.duration(story.playSeconds)}',
                      expanded: true,
                      onPressed: () => _togglePlay(chapters.length),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      onPressed: () => _share(context),
                      icon: const Icon(Icons.share_outlined, size: 18),
                      label: const Text('Share'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: () => _export(context),
                  icon: const Icon(Icons.download_outlined, size: 18),
                  label: const Text('Export manifest'),
                ),
              ),
            ],
          ),
        );
        return ResponsiveScaffold(
          title: 'Stories',
          tabIndex: 0,
          mobile: body,
          wide: body,
        );
      },
    );
  }
}
