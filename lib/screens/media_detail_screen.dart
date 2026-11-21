import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../models/memory_item.dart';
import '../models/person.dart';
import '../state/archive_controller.dart';
import '../widgets/app_shell.dart';
import '../widgets/common.dart';
import '../widgets/frame_tile.dart';
import '../widgets/layer_history.dart';

/// Media detail (m07 / w07): Frame 042 — 1.85:1 Cinema flat, scene,
/// tags, cover pick — plus the layer history underneath.
class MediaDetailScreen extends StatefulWidget {
  /// Creates the media detail screen.
  const MediaDetailScreen({required this.itemId, super.key});

  /// The memory item to show.
  final String itemId;

  @override
  State<MediaDetailScreen> createState() => _MediaDetailScreenState();
}

class _MediaDetailScreenState extends State<MediaDetailScreen> {
  late final TextEditingController _captionController;
  late final TextEditingController _tagController;
  bool _editingCaption = false;

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController();
    _tagController = TextEditingController();
  }

  @override
  void dispose() {
    _captionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _delete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this memory?'),
        content: const Text(
          'Deletion is real: the item and its layers leave the index. '
          'In v0.1 the demo library is metadata only, so there is no '
          'original file to touch.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Keep it'),
          ),
          FilledButton(
            onPressed: () {
              AppScope.of(context).archive.deleteItem(widget.itemId);
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Memory deleted')),
              );
            },
            child: const Text('Delete'),
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
        final item = archive.itemById(widget.itemId);
        if (item == null) {
          return ResponsiveScaffold(
            title: 'Media',
            tabIndex: 2,
            mobile: const EmptyState(
              icon: Icons.photo_outlined,
              title: 'Frame not found',
              body: 'This frame is no longer in the archive.',
            ),
            wide: const EmptyState(
              icon: Icons.photo_outlined,
              title: 'Frame not found',
              body: 'This frame is no longer in the archive.',
            ),
          );
        }
        final caption = archive.captionFor(item);
        if (!_editingCaption) {
          _captionController.text = caption;
        }
        final layers = archive.layersFor(item.id);
        final story =
            item.storyId == null ? null : archive.storyById(item.storyId!);
        final people = item.personIds
            .map(archive.personById)
            .whereType<Person>()
            .toList(growable: false);
        final place =
            item.placeId == null ? null : archive.placeById(item.placeId!);

        final body = SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AspectRatio(
                aspectRatio: 16 / 9,
                child: FrameTile(item: item, onTap: () {}),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      item.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  if (item.isCover)
                    const StatusPill(
                      label: 'Story cover',
                      dotColor: V7Colors.gold,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${item.aspectRatio} · ${Format.shortTimestamp(item.takenAt)}'
                '${item.widthPx > 0 ? ' · ${item.widthPx} × ${item.heightPx} px' : ''}',
                style: AppTheme.mono(size: 12),
              ),
              if (story != null) ...<Widget>[
                const SizedBox(height: 4),
                InkWell(
                  onTap: () => Navigator.of(context).pushNamed(
                    Routes.story,
                    arguments: story.id,
                  ),
                  child: Text(
                    '${story.title} ›',
                    style: AppTheme.mono(
                      size: 12,
                      color: Palette.v7.gold,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text('Caption', style: AppTheme.kicker()),
              const SizedBox(height: 8),
              if (_editingCaption)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    TextField(
                      controller: _captionController,
                      maxLines: 3,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Write the memory in your own words…',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: GradientButton(
                            label: 'Save caption',
                            expanded: true,
                            onPressed: () {
                              archive.updateCaption(
                                item.id,
                                _captionController.text.trim(),
                              );
                              setState(() => _editingCaption = false);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () =>
                              setState(() => _editingCaption = false),
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ],
                )
              else
                GlassCard(
                  onTap: () => setState(() => _editingCaption = true),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          caption.isEmpty
                              ? 'No caption yet — tap to write one.'
                              : caption,
                          style: TextStyle(
                            color: caption.isEmpty
                                ? Palette.v7.muted
                                : Palette.v7.ink,
                          ),
                        ),
                      ),
                      const Icon(Icons.edit_outlined,
                          size: 18, color: V7Colors.muted),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Text('Tags', style: AppTheme.kicker()),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final tag in item.tags)
                    TagChip(
                      tag,
                      onRemove: () => archive.removeTag(item.id, tag),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _tagController,
                      decoration: const InputDecoration(
                        hintText: 'Add a tag…',
                      ),
                      onSubmitted: (_) => _addTag(archive),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _addTag(archive),
                    tooltip: 'Add tag',
                  ),
                ],
              ),
              if (people.isNotEmpty) ...<Widget>[
                const SizedBox(height: 16),
                Text('People', style: AppTheme.kicker()),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: <Widget>[
                    for (final person in people)
                      TagChip(person.displayName),
                  ],
                ),
              ],
              if (place != null) ...<Widget>[
                const SizedBox(height: 16),
                Text('Place', style: AppTheme.kicker()),
                const SizedBox(height: 8),
                TagChip(place.name),
              ],
              const SizedBox(height: 16),
              Text('Provenance', style: AppTheme.kicker()),
              const SizedBox(height: 8),
              Text(
                'SHA-256 ${item.checksum.substring(0, 16)}…\n'
                'Source ${item.id} · ${item.isDemo ? 'demo library' : 'imported'}',
                style: AppTheme.mono(size: 11),
              ),
              const SizedBox(height: 16),
              if (item.storyId != null)
                OutlinedButton.icon(
                  onPressed: item.isCover
                      ? null
                      : () {
                          archive.setCover(item.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Made story cover'),
                            ),
                          );
                        },
                  icon: const Icon(Icons.star_outline, size: 18),
                  label: Text(
                    item.isCover ? 'This is the story cover' : 'Make story cover',
                  ),
                ),
              if (item.kind == MediaKind.voiceNote) ...<Widget>[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed(
                    Routes.voiceNote,
                    arguments: item.id,
                  ),
                  icon: const Icon(Icons.mic_outlined, size: 18),
                  label: const Text('Open voice note'),
                ),
              ],
              const SizedBox(height: 24),
              Text(
                'Layers · ${layers.length}',
                style: AppTheme.kicker(),
              ),
              const SizedBox(height: 4),
              Text(
                'Every edit is a layer. Older layers stay visible beneath — revert the top layer to reveal what was there before.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall!
                    .copyWith(color: Palette.v7.muted),
              ),
              const SizedBox(height: 8),
              LayerHistory(
                layers: layers,
                onRevert: (layerId) {
                  archive.revertLayer(layerId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Layer reverted')),
                  );
                },
              ),
              const SizedBox(height: 24),
              Center(
                child: TextButton.icon(
                  onPressed: () => _delete(context),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete this memory'),
                  style: TextButton.styleFrom(
                    foregroundColor: Palette.v7.danger,
                  ),
                ),
              ),
            ],
          ),
        );
        return ResponsiveScaffold(
          title: 'Media',
          tabIndex: 2,
          mobile: body,
          wide: body,
        );
      },
    );
  }

  void _addTag(ArchiveController archive) {
    final tag = _tagController.text.trim();
    if (tag.isEmpty) {
      return;
    }
    archive.addTag(widget.itemId, tag);
    _tagController.clear();
  }
}
