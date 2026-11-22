import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../core/format.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../models/voice_note.dart';
import '../services/audio_playback.dart';
import '../services/voice_recorder.dart';
import '../widgets/app_shell.dart';
import '../widgets/common.dart';
import '../widgets/waveform.dart';

/// Voice note (m13 / w13): waveform, transcript, attach to a story.
/// The transcript makes the note searchable — ask what Dad said about
/// the drive and this answers.
///
/// Playback is real audio from the BlobStore: the waveform is peaks
/// computed from the recording, and the playhead follows the player.
/// Notes with no stored audio say so honestly
/// instead of animating a fake playhead. The mic button records a
/// new note on this device — nothing is uploaded.
class VoiceNoteScreen extends StatefulWidget {
  /// Creates the voice note screen.
  const VoiceNoteScreen({required this.noteId, super.key});

  /// The voice note to show.
  final String noteId;

  @override
  State<VoiceNoteScreen> createState() => _VoiceNoteScreenState();
}

class _VoiceNoteScreenState extends State<VoiceNoteScreen> {
  late final AudioPlaybackController _playback;
  late final VoiceRecorderService _recorder;
  String? _loadedNoteId;
  bool _audioMissing = false;

  @override
  void initState() {
    super.initState();
    _playback = AudioPlaybackController();
    _recorder = VoiceRecorderService();
  }

  @override
  void dispose() {
    _playback.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _loadAudio(VoiceNote note) async {
    final loaded = await _playback.load(note);
    if (!mounted) {
      return;
    }
    setState(() => _audioMissing = !loaded);
  }

  void _showRecordSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _RecordSheet(
        recorder: _recorder,
        onSaved: (recorded) {
          final archive = AppScope.of(context).archive;
          archive.addVoiceNote(recorded.note, recorded.item);
          Navigator.of(sheetContext).pop();
          Navigator.of(context).pushNamed(
            Routes.voiceNote,
            arguments: recorded.note.id,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Voice note saved to the archive')),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final archive = AppScope.of(context).archive;
    return ListenableBuilder(
      listenable: archive,
      builder: (context, _) {
        final note = archive.voiceNoteById(widget.noteId);
        if (note == null) {
          return ResponsiveScaffold(
            title: 'Voice note',
            tabIndex: 2,
            floatingActionButton: FloatingActionButton(
              onPressed: _showRecordSheet,
              tooltip: 'Record a voice note',
              child: const Icon(Icons.mic),
            ),
            mobile: const EmptyState(
              icon: Icons.mic_outlined,
              title: 'Voice note not found',
              body: 'This note is no longer in the archive.',
            ),
            wide: const EmptyState(
              icon: Icons.mic_outlined,
              title: 'Voice note not found',
              body: 'This note is no longer in the archive.',
            ),
          );
        }
        if (_loadedNoteId != note.id) {
          _loadedNoteId = note.id;
          _audioMissing = false;
          _loadAudio(note);
        }
        final story = note.storyId == null
            ? null
            : archive.storyById(note.storyId!);
        final attached = note.attachedMemoryId == null
            ? null
            : archive.itemById(note.attachedMemoryId!);

        final body = SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                story == null ? 'Voice note' : story.title,
                style: AppTheme.kicker(),
              ),
              const SizedBox(height: 6),
              Text(
                note.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                '${Format.duration(note.durationSeconds)} · '
                '${Format.shortTimestamp(note.takenAt)}',
                style: AppTheme.mono(size: 12),
              ),
              const SizedBox(height: 20),
              ListenableBuilder(
                listenable: _playback,
                builder: (context, _) {
                  final elapsed = _playback.position.inSeconds;
                  final total = _playback.duration.inSeconds > 0
                      ? _playback.duration.inSeconds
                      : note.durationSeconds;
                  return GlassCard(
                    child: Column(
                      children: <Widget>[
                        Waveform(
                          heights: note.waveform,
                          progress: _playback.progress,
                          onSeek: _audioMissing
                              ? null
                              : (next) => _playback.seek(
                                    Duration(
                                      milliseconds:
                                          (next * _playback.duration.inMilliseconds)
                                              .round(),
                                    ),
                                  ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            IconButton(
                              icon: Icon(
                                _playback.isPlaying
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_filled,
                                size: 44,
                                color: Palette.v7.gold,
                              ),
                              onPressed: _audioMissing
                                  ? null
                                  : () {
                                      if (_playback.isPlaying) {
                                        _playback.pause();
                                      } else {
                                        _playback.play();
                                      }
                                    },
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${Format.duration(elapsed)} / '
                              '${Format.duration(total)}',
                              style: AppTheme.mono(size: 12),
                            ),
                            const Spacer(),
                            Text(
                              _audioMissing
                                  ? 'No recording'
                                  : 'Recorded audio',
                              style: AppTheme.mono(size: 11),
                            ),
                          ],
                        ),
                        if (_audioMissing)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'This note has no audio recording — it came '
                              'from the demo library. Record a new note '
                              'with the mic button to hear real playback.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall!
                                  .copyWith(color: Palette.v7.muted),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Text('Transcript', style: AppTheme.kicker()),
              const SizedBox(height: 8),
              GlassCard(
                child: Text(
                  note.transcript.isEmpty
                      ? 'No transcript — transcription is not available '
                          'in this version. The recording itself is '
                          'stored in full.'
                      : note.transcript,
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        color: note.transcript.isEmpty
                            ? Palette.v7.muted
                            : null,
                      ),
                ),
              ),
              if (note.transcript.isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  'The transcript is searchable — ask what was said and this note answers.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall!
                      .copyWith(color: Palette.v7.muted),
                ),
              ],
              const SizedBox(height: 16),
              Text('Attach to', style: AppTheme.kicker()),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: note.storyId,
                hint: const Text('No story attached'),
                items: <DropdownMenuItem<String>>[
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('No story'),
                  ),
                  for (final s in archive.stories)
                    DropdownMenuItem<String>(
                      value: s.id,
                      child: Text(s.title),
                    ),
                ],
                onChanged: (storyId) {
                  archive.attachVoiceNote(note.id, storyId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        storyId == null
                            ? 'Detached from story'
                            : 'Attached to ${archive.storyById(storyId)?.title ?? 'story'}',
                      ),
                    ),
                  );
                },
              ),
              if (attached != null) ...<Widget>[
                const SizedBox(height: 12),
                GlassCard(
                  onTap: () => Navigator.of(context).pushNamed(
                    Routes.media,
                    arguments: attached.id,
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.photo_outlined, color: V7Colors.gold),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Attached to ${attached.title}',
                              style:
                                  Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              'Tap to open the memory',
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
            ],
          ),
        );
        return ResponsiveScaffold(
          title: 'Voice note',
          tabIndex: 2,
          floatingActionButton: FloatingActionButton(
            onPressed: _showRecordSheet,
            tooltip: 'Record a voice note',
            child: const Icon(Icons.mic),
          ),
          mobile: body,
          wide: body,
        );
      },
    );
  }
}

/// The record-a-note bottom sheet: title, record/stop, live level.
///
/// Permission is requested when the user taps Record, with honest
/// copy about where the audio goes. Saving stores the bytes in the
/// BlobStore and hands the note + item to [onSaved].
class _RecordSheet extends StatefulWidget {
  /// Creates the record sheet.
  const _RecordSheet({required this.recorder, required this.onSaved});

  /// The recorder service (owned by the screen).
  final VoiceRecorderService recorder;

  /// Called with the finished recording.
  final void Function(RecordedVoiceNote recorded) onSaved;

  @override
  State<_RecordSheet> createState() => _RecordSheetState();
}

class _RecordSheetState extends State<_RecordSheet> {
  final TextEditingController _titleController = TextEditingController();
  Timer? _timer;
  StreamSubscription<double>? _levelSub;
  bool _recording = false;
  bool _saving = false;
  int _elapsedSeconds = 0;
  double _level = 0;
  String? _error;

  @override
  void dispose() {
    _timer?.cancel();
    _levelSub?.cancel();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    setState(() => _error = null);
    if (!await widget.recorder.ensurePermission()) {
      setState(
        () => _error = 'Microphone access was declined. Recording needs '
            'the microphone — allow it in the browser prompt (or your '
            'device settings) and try again.',
      );
      return;
    }
    final started = await widget.recorder.start();
    if (!started) {
      setState(
        () => _error = 'Could not start recording — the archive storage '
            'is not available right now.',
      );
      return;
    }
    _levelSub = widget.recorder.liveLevel.listen((level) {
      if (mounted) {
        setState(() => _level = level);
      }
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _elapsedSeconds++);
      }
    });
    setState(() {
      _recording = true;
      _elapsedSeconds = 0;
      _level = 0;
    });
  }

  Future<void> _stopAndSave() async {
    setState(() => _saving = true);
    _timer?.cancel();
    _levelSub?.cancel();
    final title = _titleController.text.trim().isEmpty
        ? 'Voice note · ${Format.shortTimestamp(DateTime.now())}'
        : _titleController.text.trim();
    try {
      final recorded = await widget.recorder.stopAndSave(title: title);
      if (!mounted) {
        return;
      }
      if (recorded == null) {
        setState(() {
          _saving = false;
          _recording = false;
          _error = 'Nothing was recording — tap Record and try again.';
        });
        return;
      }
      widget.onSaved(recorded);
    } on StateError catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
        _recording = false;
        _error = 'Could not save the recording: ${e.message}';
      });
    }
  }

  Future<void> _cancel() async {
    _timer?.cancel();
    _levelSub?.cancel();
    await widget.recorder.cancel();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('Record a voice note', style: AppTheme.kicker()),
          const SizedBox(height: 8),
          Text(
            'Your voice is recorded on this device and stored in your '
            'archive. Nothing is uploaded.',
            style: Theme.of(context)
                .textTheme
                .bodySmall!
                .copyWith(color: Palette.v7.muted),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            enabled: !_recording && !_saving,
            decoration: const InputDecoration(
              hintText: 'Title (optional)',
            ),
          ),
          if (_recording) ...<Widget>[
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Recording · ${Format.duration(_elapsedSeconds)}',
                  style: AppTheme.mono(size: 13),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: _level,
              color: Palette.v7.gold,
              backgroundColor: Palette.v7.glassStrong,
            ),
            const SizedBox(height: 4),
            Text(
              'Speak normally — the bar follows your voice.',
              style: AppTheme.mono(size: 11, color: Palette.v7.muted),
            ),
          ],
          if (_error != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall!
                  .copyWith(color: Palette.v7.danger),
            ),
          ],
          const SizedBox(height: 20),
          if (!_recording)
            GradientButton(
              icon: Icons.mic,
              label: 'Record',
              expanded: true,
              onPressed: _saving ? null : _startRecording,
            )
          else
            GradientButton(
              icon: Icons.stop,
              label: _saving ? 'Saving…' : 'Stop and save',
              expanded: true,
              onPressed: _saving ? null : _stopAndSave,
            ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _saving ? null : _cancel,
            child: Text(_recording ? 'Discard recording' : 'Cancel'),
          ),
        ],
      ),
    );
  }
}
