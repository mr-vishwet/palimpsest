import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'core/theme.dart';
import 'models/archive_data.dart';
import 'screens/corrupt_state_screen.dart';
import 'services/archive_store.dart';
import 'services/blob_store.dart';
import 'services/blob_store_access.dart';
import 'state/archive_controller.dart';
import 'state/ask_controller.dart';
import 'state/auth_controller.dart';

/// Entry point.
///
/// Local-first: the archive loads from on-device storage before the
/// first frame. On a first run there is no stored archive, so an
/// empty archive is written and the bundled demo media loads through
/// the real import pipeline after the first frame. A v1 document
/// (SharedPreferences JSON) is migrated into the Drift store on
/// load, with seeded demo content dropped.
///
/// A stored archive that cannot be read is never treated as a first
/// run (that would persist an empty archive over the user's data):
/// the recovery screen offers retry or start-fresh instead.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _boot();
}

/// Loads the archive and runs the app — or the recovery screen when
/// the stored archive cannot be read. Re-runnable: retry and
/// start-fresh both call back into [_boot] with a fresh store.
Future<void> _boot() async {
  final store = ArchiveStore();
  ArchiveData? stored;
  try {
    stored = await store.load();
  } on ArchiveLoadException catch (error) {
    runApp(
      MaterialApp(
        title: 'Palimpsest',
        theme: AppTheme.current,
        debugShowCheckedModeBanner: false,
        home: CorruptStateScreen(
          detail: error.message,
          onRetry: () => unawaited(_boot()),
          onStartFresh: () => unawaited(_startFresh(store)),
        ),
      ),
    );
    return;
  }
  final data = stored ?? ArchiveData.empty();
  final isFirstRun = stored == null;
  if (isFirstRun) {
    await store.save(data);
  }

  final blobs = BlobStore();
  BlobStoreAccess.register(blobs);

  final archive = ArchiveController(
    store: store,
    initialData: data,
    blobStore: blobs,
  );
  final ask = AskController(archive: archive);
  final auth = AuthController(archive: archive);

  runApp(
    PalimpsestApp(
      archive: archive,
      ask: ask,
      auth: auth,
      showFirstLaunch: isFirstRun,
    ),
  );

  // First run only: load the bundled demo media through the real
  // import pipeline, after the first frame so first paint is never
  // blocked. Failures skip per file and never crash the launch.
  if (isFirstRun) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        archive.loadDemoMedia().then(
          (result) {
            if (result.failures.isNotEmpty) {
              debugPrint(
                'Demo media: ${result.failures.length} files skipped',
              );
            }
          },
          onError: (Object error) {
            debugPrint('Demo media failed to load: $error');
          },
        ),
      );
    });
  }
}

/// Deletes the stored archive and boots again, empty. Clear needs
/// the same database that failed to load; if it fails too, the next
/// boot shows the recovery screen again and the user can retry.
Future<void> _startFresh(ArchiveStore store) async {
  try {
    await store.clear();
  } catch (_) {
    // The recovery screen reappears on the next boot (see above).
  }
  await _boot();
}
