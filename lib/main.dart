import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'services/archive_store.dart';
import 'services/demo_seed.dart';
import 'state/archive_controller.dart';
import 'state/ask_controller.dart';
import 'state/auth_controller.dart';

/// Entry point.
///
/// Local-first: the archive loads from on-device storage before the first
/// frame. On a first run there is no stored archive, so the seeded demo
/// library is written — clearly labelled as demo content in the UI and
/// README — and the first-launch flow is shown.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final store = ArchiveStore();
  final stored = await store.load();
  final data = stored ?? DemoSeed.build();
  if (stored == null) {
    await store.save(data);
  }

  final archive = ArchiveController(store: store, initialData: data);
  final ask = AskController(archive: archive);
  final auth = AuthController(archive: archive);

  runApp(
    PalimpsestApp(
      archive: archive,
      ask: ask,
      auth: auth,
      showFirstLaunch: stored == null,
    ),
  );
}
