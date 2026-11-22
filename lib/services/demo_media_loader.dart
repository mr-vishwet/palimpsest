import 'package:flutter/services.dart';

import '../state/archive_controller.dart';
import 'import_service.dart';

/// The result of a demo-media load: what landed and what did not.
/// A failure never aborts the load — each file skips with a reason.
class DemoMediaLoadResult {
  /// Creates a load result.
  const DemoMediaLoadResult({
    required this.loaded,
    required this.skipped,
    required this.failures,
  });

  /// Files imported into the archive.
  final int loaded;

  /// Files already in the archive (same bytes, deduped by checksum).
  final int skipped;

  /// Files that could not be imported, with reasons.
  final List<ImportFailure> failures;

  /// True when every file either loaded or was already present.
  bool get allSucceeded => failures.isEmpty;
}

/// Loads the bundled demo media through the real import pipeline.
///
/// The demo set (`assets/demo/`) is real photos and videos shipped
/// with the app so a first run has something to look at. It is NOT
/// seed data: every file goes through [ImportService] — EXIF parse,
/// thumbnail generation, SHA-256 of the file bytes — exactly like a
/// file the user picks, and lands flagged `isDemo` so the UI can say
/// so and Settings can clear it.
///
/// The file list comes from the asset manifest (no hardcoded list),
/// so adding or removing demo files needs no code change. Loading is
/// lazy: the caller runs it after the first frame, never blocking
/// first paint.
class DemoMediaLoader {
  /// Creates a loader over [importer].
  DemoMediaLoader({required ImportService importer}) : _importer = importer;

  /// The asset folder holding the demo media.
  static const String demoAssetPrefix = 'assets/demo/';

  final ImportService _importer;

  /// Loads the demo media into [archive]. Returns how many files
  /// loaded, how many were already present, and any failures.
  Future<DemoMediaLoadResult> loadInto(ArchiveController archive) async {
    final manifest =
        await AssetManifest.loadFromAssetBundle(rootBundle);
    final paths = manifest
        .listAssets()
        .where((path) => path.startsWith(demoAssetPrefix))
        .where(_isImportable)
        .toList(growable: false)
      ..sort();

    final inputs = <ImportFileInput>[];
    final failures = <ImportFailure>[];
    for (final path in paths) {
      final name = path.substring(demoAssetPrefix.length);
      try {
        final data = await rootBundle.load(path);
        inputs.add(
          ImportFileInput(
            name: name,
            bytes: data.buffer.asUint8List(),
          ),
        );
      } catch (e) {
        failures.add(
          ImportFailure(name: name, reason: 'Could not read this file'),
        );
      }
    }

    final result = await _importer.importFiles(inputs, isDemo: true);
    final added = archive.addImportedItems(result.imported);
    archive.recordImport(
      total: result.total,
      imported: result.imported.length,
    );
    return DemoMediaLoadResult(
      loaded: added,
      skipped: result.imported.length - added,
      failures: <ImportFailure>[...failures, ...result.failures],
    );
  }

  static bool _isImportable(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0) {
      return false;
    }
    final ext = path.substring(dot + 1).toLowerCase();
    return ImportService.photoExtensions.contains(ext) ||
        ImportService.videoExtensions.contains(ext);
  }
}
