import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../services/import_service.dart';
import '../widgets/app_shell.dart';
import '../widgets/common.dart';

/// Import (m14 / w14): photos and videos land here first.
///
/// The user picks files from the device; each file is hashed,
/// thumbnailed and stored locally (original bytes in the blob store,
/// metadata in the archive). Nothing is uploaded. A bad file skips
/// with a reason and never aborts the batch; re-importing the same
/// file is a no-op (matched by checksum).
class ImportScreen extends StatefulWidget {
  /// Creates the import screen.
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  bool _importing = false;
  int _done = 0;
  int _total = 0;
  String _currentName = '';
  ImportResult? _result;
  int _added = 0;

  Future<void> _pickAndImport() async {
    final archive = AppScope.of(context).archive;
    // file_picker 13: pickFiles returns the picked files directly
    // (an empty list when the user cancels); bytes are read per
    // file with readAsBytes(), on every platform.
    final picked = await FilePicker.pickFiles(type: FileType.media);
    if (picked.isEmpty || !mounted) {
      return;
    }
    final inputs = <ImportFileInput>[];
    final unreadable = <ImportFailure>[];
    for (final file in picked) {
      try {
        final bytes = await file.readAsBytes();
        inputs.add(ImportFileInput(name: file.name, bytes: bytes));
      } catch (_) {
        unreadable.add(
          ImportFailure(
            name: file.name,
            reason: 'Could not read this file',
          ),
        );
      }
    }
    setState(() {
      _importing = true;
      _done = 0;
      _total = inputs.length;
      _currentName = '';
      _result = null;
      _added = 0;
    });
    final service = ImportService(blobs: archive.blobStore);
    final result = await service.importFiles(
      inputs,
      onProgress: (done, total, currentName) {
        if (!mounted) {
          return;
        }
        setState(() {
          _done = done;
          _total = total;
          _currentName = currentName;
        });
      },
    );
    if (!mounted) {
      return;
    }
    final merged = ImportResult(
      imported: result.imported,
      failures: <ImportFailure>[...unreadable, ...result.failures],
    );
    final added = archive.addImportedItems(merged.imported);
    archive.recordImport(total: merged.total, imported: added);
    setState(() {
      _importing = false;
      _result = merged;
      _added = added;
    });
  }

  @override
  Widget build(BuildContext context) {
    final archive = AppScope.of(context).archive;
    return ListenableBuilder(
      listenable: archive,
      builder: (context, _) {
        final state = archive.importState;
        final result = _result;
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
                    Text(
                      'Add photos & videos',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pick files from this device. Originals are stored '
                      'locally at full quality; nothing is uploaded.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    GradientButton(
                      label: _importing ? 'Importing…' : 'Choose photos & videos',
                      expanded: true,
                      onPressed: _importing ? null : _pickAndImport,
                    ),
                  ],
                ),
              ),
              if (_importing) ...<Widget>[
                const SizedBox(height: 16),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            'Importing',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          StatusPill(
                            label: 'Importing',
                            dotColor: Palette.v7.gold,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: _total <= 0 ? null : _done / _total,
                        color: Palette.v7.gold,
                        backgroundColor: Palette.v7.glassStrong,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currentName.isEmpty
                            ? '$_done of $_total files'
                            : '$_done of $_total · $_currentName',
                        style: AppTheme.mono(size: 12),
                      ),
                    ],
                  ),
                ),
              ],
              if (result != null) ...<Widget>[
                const SizedBox(height: 16),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            result.allSucceeded
                                ? 'Import complete'
                                : 'Import finished with skips',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          StatusPill(
                            label: result.allSucceeded ? 'Done' : 'Skips',
                            dotColor: result.allSucceeded
                                ? Palette.v7.green
                                : Palette.v7.gold,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${Format.count(_added)} added to your archive'
                        '${result.imported.length > _added ? ' · ${Format.count(result.imported.length - _added)} already in your archive' : ''}'
                        '${result.failures.isEmpty ? '' : ' · ${Format.count(result.failures.length)} skipped'}',
                        style: AppTheme.mono(size: 12),
                      ),
                      for (final failure in result.failures)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${failure.name} — ${failure.reason}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall!
                                .copyWith(color: Palette.v7.muted),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Your archive',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${Format.count(archive.items.length)} memories · '
                      '${Format.count(state.indexed)} imported in total · '
                      '0 bytes uploaded',
                      style: AppTheme.mono(size: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Imports are stored on this device only. Photos keep '
                'their capture date and location when the file carries '
                'them; videos get their length and size when first played.',
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
