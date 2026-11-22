import 'dart:async';
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';

import '../core/format.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../engine/exporter.dart';
import '../models/memory_item.dart';
import '../models/story.dart';
import '../services/audio_playback.dart';
import '../services/blob_store_access.dart';
import '../services/export_delivery.dart';
import '../services/video_source.dart';
import '../widgets/app_shell.dart';
import '../widgets/common.dart';
import '../widgets/story_card.dart';
import '../widgets/waveform.dart';

/// Story detail (m02 / w02): chapters, counts, play time, play and
/// share. Chapters carry their own play times; the story total is the
/// sum of its chapters.
///
/// Play is real now: the player walks the story's chapters and plays
/// each memory — photos shown, videos played, voice notes played —
/// instead of stepping through chapters on a 6-second timer. Export
/// downloads a .zip with the manifest and the real media bytes.
class StoryDetailScreen extends StatefulWidget {
  /// Creates the story detail screen.
  const StoryDetailScreen({required this.storyId, super.key});

  /// The story to show.
  final String storyId;

  @override
  State<StoryDetailScreen> createState() => _StoryDetailScreenState();
}

/// One playable step: an item inside its chapter.
class _PlayItem {
  /// Creates a play step.
  const _PlayItem({required this.chapterIndex, required this.item});

  /// Index into the story's ordered chapters (-1 for unplaced items).
  final int chapterIndex;

  /// The memory to show or play.
  final MemoryItem item;
}

class _StoryDetailScreenState extends State<StoryDetailScreen> {
  /// How long a photo or written note stays on screen.
  static const Duration _stillDwell = Duration(seconds: 4);

  bool _playing = false;
  bool _paused = false;
  bool _exporting = false;
  List<_PlayItem> _playlist = const <_PlayItem>[];
  int _playIndex = 0;

  // Current-item media. Only one kind is live at a time.
  VideoSourceHandle? _videoHandle;
  AudioPlaybackController? _audio;
  Timer? _dwellTimer;
  Duration _dwellElapsed = Duration.zero;
  Uint8List? _photoBytes;
  bool _photoMissing = false;
  int _loadGen = 0;

  @override
  void dispose() {
    _disposeCurrent();
    super.dispose();
  }

  List<MemoryItem> _itemsInChapter(String chapterId) {
    final archive = AppScope.of(context).archive;
    final items = archive.items
        .where((i) => i.storyId == widget.storyId && i.chapterId == chapterId)
        .toList(growable: false)
      ..sort((a, b) => a.takenAt.compareTo(b.takenAt));
    return items;
  }

  int _playSecondsFor(List<MemoryItem> items) {
    var total = 0;
    for (final item in items) {
      switch (item.kind) {
        case MediaKind.video:
        case MediaKind.voiceNote:
          total += item.durationSeconds ?? 0;
        case MediaKind.photo:
        case MediaKind.note:
          total += _stillDwell.inSeconds;
      }
    }
    return total;
  }

  void _startPlayback() {
    final archive = AppScope.of(context).archive;
    final story = archive.storyById(widget.storyId);
    if (story == null) {
      return;
    }
    final playlist = <_PlayItem>[];
    final chapters = story.orderedChapters;
    for (var i = 0; i < chapters.length; i++) {
      for (final item in _itemsInChapter(chapters[i].id)) {
        playlist.add(_PlayItem(chapterIndex: i, item: item));
      }
    }
    if (playlist.isEmpty) {
      // A story whose memories were never placed in chapters still
      // plays, in chronological order.
      final unplaced = archive.items
          .where((i) => i.storyId == story.id)
          .toList(growable: false)
        ..sort((a, b) => a.takenAt.compareTo(b.takenAt));
      for (final item in unplaced) {
        playlist.add(_PlayItem(chapterIndex: -1, item: item));
      }
    }
    if (playlist.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nothing to play yet — add memories to this story.'),
        ),
      );
      return;
    }
    setState(() {
      _playing = true;
      _paused = false;
      _playlist = playlist;
      _playIndex = 0;
    });
    _loadCurrent();
  }

  void _stopPlayback() {
    _disposeCurrent();
    setState(() {
      _playing = false;
      _paused = false;
      _playlist = const <_PlayItem>[];
      _playIndex = 0;
    });
  }

  void _next() {
    if (!_playing) {
      return;
    }
    if (_playIndex + 1 >= _playlist.length) {
      _stopPlayback();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Story finished')),
      );
      return;
    }
    setState(() => _playIndex++);
    _loadCurrent();
  }

  void _previous() {
    if (!_playing || _playIndex == 0) {
      return;
    }
    setState(() => _playIndex--);
    _loadCurrent();
  }

  void _togglePause() {
    if (!_playing) {
      return;
    }
    final item = _playlist[_playIndex].item;
    if (_paused) {
      setState(() => _paused = false);
      switch (item.kind) {
        case MediaKind.video:
          _videoHandle?.controller.play();
        case MediaKind.voiceNote:
          _audio?.play();
        case MediaKind.photo:
        case MediaKind.note:
          _startDwellTimer();
      }
    } else {
      setState(() => _paused = true);
      switch (item.kind) {
        case MediaKind.video:
          _videoHandle?.controller.pause();
        case MediaKind.voiceNote:
          _audio?.pause();
        case MediaKind.photo:
        case MediaKind.note:
          _dwellTimer?.cancel();
      }
    }
  }

  void _disposeCurrent() {
    _loadGen++;
    _dwellTimer?.cancel();
    _dwellTimer = null;
    final video = _videoHandle;
    if (video != null) {
      video.controller.removeListener(_onVideoTick);
      unawaited(video.release());
      _videoHandle = null;
    }
    final audio = _audio;
    if (audio != null) {
      audio.removeListener(_onAudioTick);
      audio.dispose();
      _audio = null;
    }
    _photoBytes = null;
    _photoMissing = false;
    _dwellElapsed = Duration.zero;
  }

  void _onVideoTick() {
    final controller = _videoHandle?.controller;
    if (controller == null || !_playing) {
      return;
    }
    if (controller.value.isCompleted) {
      _next();
      return;
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _onAudioTick() {
    final audio = _audio;
    if (audio == null || !_playing) {
      return;
    }
    if (!audio.isPlaying &&
        audio.duration > Duration.zero &&
        audio.progress >= 1) {
      _next();
      return;
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _startDwellTimer() {
    _dwellTimer?.cancel();
    _dwellTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted || !_playing) {
        timer.cancel();
        return;
      }
      _dwellElapsed += const Duration(milliseconds: 100);
      if (_dwellElapsed >= _stillDwell) {
        timer.cancel();
        _next();
        return;
      }
      setState(() {});
    });
  }

  Future<void> _loadCurrent() async {
    _disposeCurrent();
    if (!_playing || _playIndex >= _playlist.length) {
      return;
    }
    final gen = _loadGen;
    final item = _playlist[_playIndex].item;
    final store = BlobStoreAccess.current;
    switch (item.kind) {
      case MediaKind.photo:
        if (item.blobId == null || store == null) {
          _showStill(missing: true);
          return;
        }
        final bytes = await store.get(item.blobId!);
        if (!mounted || gen != _loadGen) {
          return;
        }
        setState(() {
          _photoBytes = bytes;
          _photoMissing = bytes == null;
        });
        _startDwellTimer();
      case MediaKind.note:
        _showStill(missing: false);
      case MediaKind.video:
        if (item.blobId == null || store == null) {
          _showStill(missing: true);
          return;
        }
        final bytes = await store.get(item.blobId!);
        if (!mounted || gen != _loadGen) {
          return;
        }
        if (bytes == null) {
          _showStill(missing: true);
          return;
        }
        VideoSourceHandle? handle;
        try {
          handle = await VideoSource.fromBytes(
            bytes,
            item.mimeType ?? 'video/mp4',
          );
          await handle.controller.initialize();
          if (!mounted || gen != _loadGen) {
            await handle.release();
            return;
          }
          handle.controller.addListener(_onVideoTick);
          setState(() => _videoHandle = handle);
          if (!_paused) {
            await handle.controller.play();
          }
        } catch (_) {
          await handle?.release();
          if (mounted && gen == _loadGen) {
            _showStill(missing: true);
          }
        }
      case MediaKind.voiceNote:
        final archive = AppScope.of(context).archive;
        final note = archive.voiceNoteById(item.id);
        if (note == null) {
          _showStill(missing: true);
          return;
        }
        final audio = AudioPlaybackController();
        final loaded = await audio.load(note);
        if (!mounted || gen != _loadGen) {
          audio.dispose();
          return;
        }
        if (!loaded) {
          audio.dispose();
          _showStill(missing: true);
          return;
        }
        audio.addListener(_onAudioTick);
        setState(() => _audio = audio);
        if (!_paused) {
          await audio.play();
        }
    }
  }

  /// Shows a still (photo without bytes, note, or unplayable media)
  /// for the dwell time, then advances.
  void _showStill({required bool missing}) {
    if (!mounted) {
      return;
    }
    setState(() => _photoMissing = missing);
    _startDwellTimer();
  }

  double get _currentProgress {
    if (_playlist.isEmpty) {
      return 0;
    }
    final item = _playlist[_playIndex].item;
    switch (item.kind) {
      case MediaKind.video:
        final value = _videoHandle?.controller.value;
        if (value == null || value.duration.inMilliseconds <= 0) {
          return 0;
        }
        return (value.position.inMilliseconds / value.duration.inMilliseconds)
            .clamp(0.0, 1.0);
      case MediaKind.voiceNote:
        return _audio?.progress ?? 0;
      case MediaKind.photo:
      case MediaKind.note:
        return (_dwellElapsed.inMilliseconds / _stillDwell.inMilliseconds)
            .clamp(0.0, 1.0);
    }
  }

  void _share(BuildContext context) {
    final scope = AppScope.of(context);
    if (!scope.auth.isSignedIn) {
      Navigator.of(context).pushNamed(Routes.upgrade, arguments: widget.storyId);
      return;
    }
    Navigator.of(context).pushNamed(Routes.share, arguments: widget.storyId);
  }

  Future<void> _export(BuildContext context) async {
    final archive = AppScope.of(context).archive;
    final story = archive.storyById(widget.storyId);
    if (story == null) {
      return;
    }
    setState(() => _exporting = true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: <Widget>[
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Expanded(child: Text('Gathering the story’s media…')),
          ],
        ),
      ),
    );
    try {
      final store = BlobStoreAccess.current;
      final mediaFiles = <String, Uint8List>{};
      final mediaEntries = <String, ExportMediaFile>{};
      var skipped = 0;
      final items = archive.itemsInStory(story.id);
      for (final item in items) {
        final blobId = item.blobId;
        if (blobId == null || store == null) {
          skipped++;
          continue;
        }
        final bytes = await store.get(blobId);
        if (bytes == null) {
          skipped++;
          continue;
        }
        final fileName = 'media/${item.id}'
            '${ExportDelivery.extensionForMimeType(item.mimeType)}';
        mediaFiles[fileName] = bytes;
        mediaEntries[item.id] = ExportMediaFile(
          fileName: fileName,
          byteSize: bytes.length,
          sha256: item.checksum,
        );
      }
      final manifest = Exporter.manifestForStory(
        story,
        archive.items,
        archive.layers,
        mediaFiles: mediaEntries,
      );
      final zip = ExportDelivery.buildZip(
        manifest: manifest,
        mediaFiles: mediaFiles,
      );
      final slug = story.title
          .toLowerCase()
          .replaceAll(RegExp('[^a-z0-9]+'), '-')
          .replaceAll(RegExp('^-|-\$'), '');
      final fileName = '${slug.isEmpty ? 'story' : slug}.zip';
      await ExportDelivery.deliverZip(zip, fileName);
      if (!context.mounted) {
        return;
      }
      Navigator.of(context).pop();
      final mb = (zip.lengthInBytes / (1024 * 1024)).toStringAsFixed(1);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Exported $fileName — ${mediaFiles.length} files, $mb MB'
            '${skipped == 0 ? '' : ' · $skipped '
                '${skipped == 1 ? 'item' : 'items'} had no stored original'}',
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
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
        final chapterItems = <List<MemoryItem>>[
          for (final chapter in chapters) _itemsInChapter(chapter.id),
        ];
        final totalPlaySeconds = chapterItems.fold(
          0,
          (sum, items) => sum + _playSecondsFor(items),
        );
        final playingChapter =
            _playing && _playlist.isNotEmpty ? _playlist[_playIndex].chapterIndex : -1;
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
              if (_playing) ...<Widget>[
                const SizedBox(height: 16),
                _buildPlayerCard(chapters),
              ],
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
                                    if (playingChapter == i)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: LinearProgressIndicator(
                                          value: _currentProgress,
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
                                Format.duration(
                                  _playSecondsFor(chapterItems[i]),
                                ),
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
                      icon: _playing ? Icons.stop : Icons.play_arrow,
                      label: _playing
                          ? 'Stop'
                          : 'Play the story · ${Format.duration(totalPlaySeconds)}',
                      expanded: true,
                      onPressed: _playing ? _stopPlayback : _startPlayback,
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
                  onPressed: _exporting ? null : () => _export(context),
                  icon: const Icon(Icons.download_outlined, size: 18),
                  label: const Text('Export story (.zip)'),
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

  Widget _buildPlayerCard(List<Chapter> chapters) {
    if (_playlist.isEmpty) {
      return const SizedBox.shrink();
    }
    final current = _playlist[_playIndex];
    final item = current.item;
    final chapterTitle = current.chapterIndex >= 0 &&
            current.chapterIndex < chapters.length
        ? chapters[current.chapterIndex].title
        : 'Unplaced';
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '$chapterTitle · ${_playIndex + 1} of ${_playlist.length}',
                  style: AppTheme.mono(size: 11, color: Palette.v7.muted),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                tooltip: 'Stop playing',
                onPressed: _stopPlayback,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(item.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _buildPlayerMedia(item),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _currentProgress,
            color: Palette.v7.gold,
            backgroundColor: Palette.v7.glassStrong,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.skip_previous),
                tooltip: 'Previous',
                onPressed: _playIndex == 0 ? null : _previous,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  _paused ? Icons.play_circle_filled : Icons.pause_circle_filled,
                  size: 44,
                  color: Palette.v7.gold,
                ),
                tooltip: _paused ? 'Resume' : 'Pause',
                onPressed: _togglePause,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.skip_next),
                tooltip: 'Next',
                onPressed: _playIndex + 1 >= _playlist.length ? null : _next,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerMedia(MemoryItem item) {
    switch (item.kind) {
      case MediaKind.photo:
        if (_photoBytes != null) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              _photoBytes!,
              height: 280,
              width: double.infinity,
              fit: BoxFit.contain,
            ),
          );
        }
        if (_photoMissing) {
          return _playerPlaceholder(
            'The original photo is not stored in this archive.',
          );
        }
        return const SizedBox(
          height: 280,
          child: Center(child: CircularProgressIndicator()),
        );
      case MediaKind.video:
        final handle = _videoHandle;
        if (handle != null && handle.controller.value.isInitialized) {
          final size = handle.controller.value.size;
          final aspect = size.height > 0 ? size.width / size.height : 16 / 9;
          return AspectRatio(
            aspectRatio: aspect,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: VideoPlayer(handle.controller),
            ),
          );
        }
        if (_photoMissing) {
          return _playerPlaceholder(
            'The original video is not stored in this archive.',
          );
        }
        return const SizedBox(
          height: 220,
          child: Center(child: CircularProgressIndicator()),
        );
      case MediaKind.voiceNote:
        final audio = _audio;
        final archive = AppScope.of(context).archive;
        final note = archive.voiceNoteById(item.id);
        if (audio != null && note != null) {
          return ListenableBuilder(
            listenable: audio,
            builder: (context, _) => Column(
              children: <Widget>[
                Waveform(
                  heights: note.waveform,
                  progress: audio.progress,
                  onSeek: (next) => audio.seek(
                    Duration(
                      milliseconds:
                          (next * audio.duration.inMilliseconds).round(),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${Format.duration(audio.position.inSeconds)} / '
                  '${Format.duration(audio.duration.inSeconds)}',
                  style: AppTheme.mono(size: 11),
                ),
              ],
            ),
          );
        }
        if (_photoMissing) {
          return _playerPlaceholder(
            'This voice note has no recording to play.',
          );
        }
        return const SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        );
      case MediaKind.note:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            item.note?.isNotEmpty == true ? item.note! : item.title,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        );
    }
  }

  Widget _playerPlaceholder(String message) {
    return SizedBox(
      height: 160,
      child: Center(
        child: Text(
          message,
          style: AppTheme.mono(size: 12, color: Palette.v7.muted),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
