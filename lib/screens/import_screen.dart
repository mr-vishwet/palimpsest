import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/archive_data.dart';
import '../widgets/app_shell.dart';
import '../widgets/common.dart';

/// Import (m14 / w14): photos, prints, voice memos — everything lands
/// here first. Indexing is honest about progress: 842 of 1,204
/// indexed, 0 bytes uploaded.
///
/// v0.1 simulates the indexing queue over the demo batch (real photo
/// library access is a phase-2 item); the queue state, progress and
/// completion are real and persisted.
class ImportScreen extends StatefulWidget {
  /// Creates the import screen.
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 600), (_) {
      if (!mounted) {
        return;
      }
      AppScope.of(context).archive.advanceImport(9);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final archive = AppScope.of(context).archive;
    return ListenableBuilder(
      listenable: archive,
      builder: (context, _) {
        final state = archive.importState;
        final indexing = state.status == ImportStatus.indexing;
        final done = state.status == ImportStatus.done;

        final sources = <({String label, String hint, IconData icon, int count})>[
          (
            label: 'Photos',
            hint: 'From the camera roll',
            icon: Icons.photo_library_outlined,
            count: 320,
          ),
          (
            label: 'Prints',
            hint: 'Scan the photo box',
            icon: Icons.scanner_outlined,
            count: 48,
          ),
          (
            label: 'Voice memos',
            hint: 'Recordings + transcripts',
            icon: Icons.mic_outlined,
            count: 12,
          ),
          (
            label: 'Files',
            hint: 'Videos and documents',
            icon: Icons.folder_outlined,
            count: 86,
          ),
        ];

        final body = SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Everything lands here first', style: AppTheme.kicker()),
              const SizedBox(height: 6),
              Text(
                'Import',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          done ? 'Indexing complete' : 'Indexing ${state.sourceLabel}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        StatusPill(
                          label: done
                              ? 'Done'
                              : indexing
                                  ? 'Indexing'
                                  : 'Paused',
                          dotColor: done
                              ? Palette.v7.green
                              : indexing
                                  ? Palette.v7.gold
                                  : Palette.v7.muted,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: state.progress,
                      color: Palette.v7.gold,
                      backgroundColor: Palette.v7.glassStrong,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${Format.count(state.indexed)} of ${Format.count(state.total)} indexed · ${(state.progress * 100).round()}% · 0 bytes uploaded',
                      style: AppTheme.mono(size: 12),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: GradientButton(
                            label: done
                                ? 'All indexed'
                                : indexing
                                    ? 'Pause'
                                    : 'Resume indexing',
                            expanded: true,
                            onPressed: done
                                ? null
                                : indexing
                                    ? archive.pauseImport
                                    : archive.startImport,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Sources', style: AppTheme.kicker()),
              const SizedBox(height: 8),
              for (final source in sources)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(
                    child: Row(
                      children: <Widget>[
                        Icon(source.icon, color: Palette.v7.gold),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                source.label,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              Text(source.hint, style: AppTheme.mono(size: 11)),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () {
                            archive.addImportBatch(
                              source.count,
                              source.label,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${source.count} items queued from ${source.label}',
                                ),
                              ),
                            );
                          },
                          child: Text('+ ${source.count}'),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                'Demo build: import queues a simulated batch into the on-device index. Real photo-library access arrives in phase 2; nothing here uploads anything.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall!
                    .copyWith(color: Palette.v7.muted),
              ),
            ],
          ),
        );
        return ResponsiveScaffold(
          title: 'Import',
          tabIndex: 2,
          mobile: body,
          wide: body,
        );
      },
    );
  }
}
