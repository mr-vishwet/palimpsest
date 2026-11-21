import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../models/story.dart';
import '../widgets/app_shell.dart';
import '../widgets/common.dart';
import '../widgets/frame_tile.dart';

/// Story compose (m08 / w08): chapters in the order you remember
/// them — drag to reorder, and the media follows. Unplaced media
/// waits below until it gets a chapter.
class ComposeScreen extends StatelessWidget {
  /// Creates the compose screen.
  const ComposeScreen({required this.storyId, super.key});

  /// The story being composed.
  final String storyId;

  @override
  Widget build(BuildContext context) {
    final archive = AppScope.of(context).archive;
    return ListenableBuilder(
      listenable: archive,
      builder: (context, _) {
        final story = archive.storyById(storyId);
        if (story == null) {
          return ResponsiveScaffold(
            title: 'Compose',
            tabIndex: 0,
            mobile: const EmptyState(
              icon: Icons.book_outlined,
              title: 'Story not found',
              body: 'This story is no longer in the archive.',
            ),
            wide: const EmptyState(
              icon: Icons.book_outlined,
              title: 'Story not found',
              body: 'This story is no longer in the archive.',
            ),
          );
        }
        final chapters = story.orderedChapters;
        final unplaced = archive.unplacedItems(story.id);
        final placed = chapters.length;
        final body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Chapters, in the order you remember them',
                      style: AppTheme.kicker()),
                  const SizedBox(height: 6),
                  Text(
                    story.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${Format.duration(story.playSeconds)} · $placed placed · ${unplaced.length} unplaced',
                    style: AppTheme.mono(size: 12),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: chapters.length,
                onReorder: (oldIndex, newIndex) {
                  final next = List<Chapter>.of(chapters);
                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }
                  final moved = next.removeAt(oldIndex);
                  next.insert(newIndex, moved);
                  archive.reorderChapters(story.id, next);
                },
                itemBuilder: (context, i) {
                  final chapter = chapters[i];
                  return Padding(
                    key: ValueKey<String>(chapter.id),
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(
                      child: Row(
                        children: <Widget>[
                          const Icon(
                            Icons.drag_handle,
                            color: V7Colors.muted,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () => Navigator.of(context).pushNamed(
                                Routes.chapterEdit,
                                arguments: <String, String>{
                                  'storyId': story.id,
                                  'chapterId': chapter.id,
                                },
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    chapter.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall,
                                  ),
                                  Text(
                                    chapter.day > 0
                                        ? 'Day ${chapter.day} · '
                                            '${Format.mediaCounts(photos: chapter.photoCount, videos: chapter.videoCount)} · '
                                            '${Format.duration(chapter.playSeconds)}'
                                        : '${Format.mediaCounts(photos: chapter.photoCount, videos: chapter.videoCount)} · '
                                            '${Format.duration(chapter.playSeconds)}',
                                    style: AppTheme.mono(size: 11),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: V7Colors.muted,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (unplaced.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Unplaced · ${unplaced.length}',
                      style: AppTheme.kicker(),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 110,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: <Widget>[
                          for (final item in unplaced)
                            Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: SizedBox(
                                width: 110,
                                child: FrameTile(
                                  item: item,
                                  onTap: () => _placeItem(
                                    context,
                                    story,
                                    item.id,
                                    chapters,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap a frame to place it in a chapter.',
                      style: AppTheme.mono(size: 11),
                    ),
                  ],
                ),
              ),
          ],
        );
        return ResponsiveScaffold(
          title: 'Compose',
          tabIndex: 0,
          mobile: body,
          wide: body,
        );
      },
    );
  }

  void _placeItem(
    BuildContext context,
    Story story,
    String itemId,
    List<Chapter> chapters,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Place in chapter'),
        children: <Widget>[
          for (final chapter in chapters)
            SimpleDialogOption(
              onPressed: () {
                AppScope.of(context)
                    .archive
                    .placeItemInChapter(itemId, chapter.id);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Placed in ${chapter.title}')),
                );
              },
              child: Text(chapter.title),
            ),
        ],
      ),
    );
  }
}
