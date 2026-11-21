import 'dart:async';

import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/common.dart';
import '../widgets/waveform.dart';

/// Voice note (m13 / w13): waveform, transcript, attach to a story.
/// The transcript makes the note searchable — ask what Dad said about
/// the drive and this answers.
///
/// Playback in v0.1 is a timed playhead over the waveform (the demo
/// library carries transcripts and waveforms, not audio bytes — real
/// audio playback is a phase-2 item, noted in the README).
class VoiceNoteScreen extends StatefulWidget {
  /// Creates the voice note screen.
  const VoiceNoteScreen({required this.noteId, super.key});

  /// The voice note to show.
  final String noteId;

  @override
  State<VoiceNoteScreen> createState() => _VoiceNoteScreenState();
}

class _VoiceNoteScreenState extends State<VoiceNoteScreen> {
  Timer? _timer;
  double _progress = 0;
  bool _playing = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _togglePlay(int durationSeconds) {
    if (_playing) {
      _timer?.cancel();
      setState(() => _playing = false);
      return;
    }
    if (_progress >= 1) {
      _progress = 0;
    }
    setState(() => _playing = true);
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _progress += 0.1 / durationSeconds;
        if (_progress >= 1) {
          _progress = 1;
          _playing = false;
          timer.cancel();
        }
      });
    });
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
        final story = note.storyId == null
            ? null
            : archive.storyById(note.storyId!);
        final attached = note.attachedMemoryId == null
            ? null
            : archive.itemById(note.attachedMemoryId!);
        final elapsed =
            (_progress * note.durationSeconds).round();

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
              GlassCard(
                child: Column(
                  children: <Widget>[
                    Waveform(
                      heights: note.waveform,
                      progress: _progress,
                      onSeek: (next) => setState(() => _progress = next),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        IconButton(
                          icon: Icon(
                            _playing
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                            size: 44,
                            color: Palette.v7.gold,
                          ),
                          onPressed: () =>
                              _togglePlay(note.durationSeconds),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${Format.duration(elapsed)} / '
                          '${Format.duration(note.durationSeconds)}',
                          style: AppTheme.mono(size: 12),
                        ),
                        const Spacer(),
                        Text(
                          'Demo playback — waveform only',
                          style: AppTheme.mono(size: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Transcript', style: AppTheme.kicker()),
              const SizedBox(height: 8),
              GlassCard(
                child: Text(
                  note.transcript,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The transcript is searchable — ask what was said and this note answers.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall!
                    .copyWith(color: Palette.v7.muted),
              ),
              const SizedBox(height: 16),
              Text('Attach to', style: AppTheme.kicker()),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: note.storyId,
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
          mobile: body,
          wide: body,
        );
      },
    );
  }
}
