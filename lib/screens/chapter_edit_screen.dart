import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/common.dart';
import '../widgets/frame_tile.dart';

/// Chapter edit (m09 / w09): title, caption, cover frame — the story
/// updates everywhere.
class ChapterEditScreen extends StatefulWidget {
  /// Creates the chapter edit screen.
  const ChapterEditScreen({
    required this.storyId,
    required this.chapterId,
    super.key,
  });

  /// The story containing the chapter.
  final String storyId;

  /// The chapter to edit.
  final String chapterId;

  @override
  State<ChapterEditScreen> createState() => _ChapterEditScreenState();
}

class _ChapterEditScreenState extends State<ChapterEditScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _captionController;
  String? _coverFrameId;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _captionController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  void _save() {
    final archive = AppScope.of(context).archive;
    archive.updateChapter(
      widget.storyId,
      widget.chapterId,
      title: _titleController.text.trim(),
      caption: _captionController.text.trim(),
      coverFrameId: _coverFrameId,
    );
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chapter updated')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final archive = AppScope.of(context).archive;
    return ListenableBuilder(
      listenable: archive,
      builder: (context, _) {
        final story = archive.storyById(widget.storyId);
        final chapter = story?.chapters
            .where((c) => c.id == widget.chapterId)
            .firstOrNull;
        if (story == null || chapter == null) {
          return ResponsiveScaffold(
            title: 'Chapter',
            tabIndex: 0,
            mobile: const EmptyState(
              icon: Icons.book_outlined,
              title: 'Chapter not found',
              body: 'This chapter is no longer in the archive.',
            ),
            wide: const EmptyState(
              icon: Icons.book_outlined,
              title: 'Chapter not found',
              body: 'This chapter is no longer in the archive.',
            ),
          );
        }
        if (!_initialized) {
          _titleController.text = chapter.title;
          _captionController.text = chapter.caption;
          _coverFrameId = chapter.coverFrameId;
          _initialized = true;
        }
        final frames = archive.items
            .where((item) => item.chapterId == chapter.id)
            .toList(growable: false);

        final body = SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('${story.title} · Chapter', style: AppTheme.kicker()),
              const SizedBox(height: 6),
              Text(
                'Edit chapter',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text('Title', style: AppTheme.kicker()),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(hintText: 'Chapter title'),
              ),
              const SizedBox(height: 16),
              Text('Caption', style: AppTheme.kicker()),
              const SizedBox(height: 8),
              TextField(
                controller: _captionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'The story in your own words…',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${Format.mediaCounts(photos: chapter.photoCount, videos: chapter.videoCount)} · ${Format.duration(chapter.playSeconds)}',
                style: AppTheme.mono(size: 12),
              ),
              const SizedBox(height: 16),
              Text('Cover frame', style: AppTheme.kicker()),
              const SizedBox(height: 4),
              Text(
                'Chosen from the chapter itself.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall!
                    .copyWith(color: Palette.v7.muted),
              ),
              const SizedBox(height: 8),
              if (frames.isEmpty)
                const Text(
                  'No frames in this chapter in the demo library yet.',
                  style: TextStyle(color: V7Colors.muted),
                )
              else
                SizedBox(
                  height: 120,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: <Widget>[
                      for (final frame in frames)
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: SizedBox(
                            width: 120,
                            child: Stack(
                              children: <Widget>[
                                FrameTile(
                                  item: frame,
                                  onTap: () => setState(
                                    () => _coverFrameId = frame.id,
                                  ),
                                ),
                                if (_coverFrameId == frame.id)
                                  const Positioned(
                                    right: 6,
                                    top: 6,
                                    child: Icon(
                                      Icons.check_circle,
                                      color: V7Colors.gold,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              GradientButton(
                label: 'Save chapter',
                expanded: true,
                onPressed: _save,
              ),
            ],
          ),
        );
        return ResponsiveScaffold(
          title: 'Chapter',
          tabIndex: 0,
          mobile: body,
          wide: body,
        );
      },
    );
  }
}
