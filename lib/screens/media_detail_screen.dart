import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';

import '../core/format.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../models/memory_item.dart';
import '../models/person.dart';
import '../services/blob_store_access.dart';
import '../services/place_clustering.dart';
import '../services/video_source.dart';
import '../state/archive_controller.dart';
import '../widgets/app_shell.dart';
import '../widgets/common.dart';
import '../widgets/frame_tile.dart';
import '../widgets/layer_history.dart';

/// Media detail (m07 / w07): Frame 042 — 1.85:1 Cinema flat, scene,
/// tags, cover pick — plus the layer history underneath.
///
/// Videos play for real here: the original bytes come from the
/// BlobStore and play through a blob URL (web) or temp file
/// (native). The first playback reports the true duration and
/// dimensions back to the archive when the import did not know them.
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
    final item = AppScope.of(context).archive.itemById(widget.itemId);
    final hasOriginal = item?.blobId != null;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this memory?'),
        content: Text(
          'Deletion is real: the item and its layers leave the index'
          '${hasOriginal ? ', and its stored original is deleted too' : ''}.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Keep it'),
          ),
          FilledButton(
            onPressed: () {
              // The controller deletes the stored originals too.
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
          return const ResponsiveScaffold(
            title: 'Media',
            tabIndex: 2,
            mobile: EmptyState(
              icon: Icons.photo_outlined,
              title: 'Frame not found',
              body: 'This frame is no longer in the archive.',
            ),
            wide: EmptyState(
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
              if (item.kind == MediaKind.video)
                _VideoPlayerSection(item: item, archive: archive)
              else
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
              if (item.gpsLat != null && item.gpsLng != null) ...<Widget>[
                const SizedBox(height: 16),
                Text('Taken at', style: AppTheme.kicker()),
                const SizedBox(height: 8),
                Text(
                  PlaceClusterer.formatCoordinates(item.gpsLat!, item.gpsLng!),
                  style: AppTheme.mono(size: 12),
                ),
              ],
              const SizedBox(height: 16),
              Text('Provenance', style: AppTheme.kicker()),
              const SizedBox(height: 8),
              Text(
                'SHA-256 ${item.checksum.substring(0, 16)}…\n'
                'Source ${item.id} · ${item.isDemo ? 'demo library' : 'imported'}'
                '${item.sourceName == null ? '' : '\nFile ${item.sourceName}'}'
                '${item.mimeType == null ? '' : ' · ${item.mimeType}'}',
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

/// Plays an imported video from its BlobStore bytes, with real
/// duration and dimensions once the player has loaded.
///
/// The first playback reports the true duration and dimensions back
/// to the archive when the import did not know them. A video with no
/// stored original (demo library) shows an honest placeholder
/// instead of a player.
class _VideoPlayerSection extends StatefulWidget {
  /// Creates the video player section.
  const _VideoPlayerSection({required this.item, required this.archive});

  /// The video item to play.
  final MemoryItem item;

  /// The archive controller, for reporting back real metadata.
  final ArchiveController archive;

  @override
  State<_VideoPlayerSection> createState() => _VideoPlayerSectionState();
}

class _VideoPlayerSectionState extends State<_VideoPlayerSection> {
  VideoSourceHandle? _handle;
  bool _loading = true;
  bool _missing = false;
  bool _reportedMetadata = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _handle?.release();
    super.dispose();
  }

  Future<void> _load() async {
    final blobId = widget.item.blobId;
    final store = BlobStoreAccess.current;
    if (blobId == null || store == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _missing = true;
        });
      }
      return;
    }
    final bytes = await store.get(blobId);
    if (!mounted) {
      return;
    }
    if (bytes == null) {
      setState(() {
        _loading = false;
        _missing = true;
      });
      return;
    }
    VideoSourceHandle? handle;
    try {
      handle = await VideoSource.fromBytes(
        bytes,
        widget.item.mimeType ?? 'video/mp4',
      );
      await handle.controller.initialize();
      if (!mounted) {
        await handle.release();
        return;
      }
      final value = handle.controller.value;
      if (!_reportedMetadata &&
          (widget.item.durationSeconds == null ||
              widget.item.widthPx == 0)) {
        _reportedMetadata = true;
        widget.archive.updateItemMedia(
          widget.item.id,
          durationSeconds: value.duration.inSeconds,
          widthPx: value.size.width.round(),
          heightPx: value.size.height.round(),
        );
      }
      setState(() {
        _handle = handle;
        _loading = false;
      });
    } catch (_) {
      await handle?.release();
      if (mounted) {
        setState(() {
          _loading = false;
          _missing = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final handle = _handle;
    if (_loading) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: GlassCard(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (_missing || handle == null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: GlassCard(
          child: Center(
            child: Text(
              'The original video is not stored in this archive.',
              style: AppTheme.mono(size: 12, color: Palette.v7.muted),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    final controller = handle.controller;
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final aspect = value.size.height > 0
            ? value.size.width / value.size.height
            : 16 / 9;
        final durationMs = value.duration.inMilliseconds;
        final positionMs = value.position.inMilliseconds.clamp(0, durationMs);
        return Column(
          children: <Widget>[
            AspectRatio(
              aspectRatio: aspect,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: VideoPlayer(controller),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                IconButton(
                  icon: Icon(
                    value.isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    size: 40,
                    color: Palette.v7.gold,
                  ),
                  onPressed: () {
                    if (value.isPlaying) {
                      controller.pause();
                    } else {
                      if (value.isCompleted) {
                        controller.seekTo(Duration.zero);
                      }
                      controller.play();
                    }
                  },
                ),
                Expanded(
                  child: Slider(
                    value: durationMs > 0
                        ? positionMs / durationMs
                        : 0,
                    onChanged: durationMs > 0
                        ? (next) => controller.seekTo(
                              Duration(
                                milliseconds: (next * durationMs).round(),
                              ),
                            )
                        : null,
                  ),
                ),
                Text(
                  '${Format.duration(value.position.inSeconds)} / '
                  '${Format.duration(value.duration.inSeconds)}',
                  style: AppTheme.mono(size: 11),
                ),
              ],
            ),
            if (value.size != Size.zero)
              Text(
                '${value.size.width.round()} × '
                '${value.size.height.round()} px',
                style: AppTheme.mono(size: 11, color: Palette.v7.muted),
              ),
          ],
        );
      },
    );
  }
}
