import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:palimpsest/core/routes.dart';
import 'package:palimpsest/screens/import_screen.dart';
import 'package:palimpsest/screens/library_screen.dart';
import 'package:palimpsest/services/archive_store.dart';
import 'package:palimpsest/services/demo_seed.dart';
import 'package:palimpsest/state/archive_controller.dart';
import 'package:palimpsest/state/ask_controller.dart';
import 'package:palimpsest/state/auth_controller.dart';
import 'package:palimpsest/widgets/app_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Library always shows Add photos & videos, and it opens Import',
    (tester) async {
      // No network in tests: fall back to bundled fonts instead of
      // fetching from Google Fonts.
      GoogleFonts.config.allowRuntimeFetching = false;
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final archive = ArchiveController(
        store: ArchiveStore(),
        initialData: DemoSeed.build(),
      );
      addTearDown(archive.dispose);
      final ask = AskController(archive: archive);
      addTearDown(ask.dispose);
      final auth = AuthController(archive: archive);
      addTearDown(auth.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: AppScope(
            archive: archive,
            ask: ask,
            auth: auth,
            child: const LibraryScreen(),
          ),
          onGenerateRoute: (settings) {
            if (settings.name == Routes.import) {
              return MaterialPageRoute<void>(
                builder: (_) => AppScope(
                  archive: archive,
                  ask: ask,
                  auth: auth,
                  child: const ImportScreen(),
                ),
                settings: settings,
              );
            }
            return null;
          },
        ),
      );
      await tester.pumpAndSettle();

      // The entry point is present on a repeat visit too: nothing
      // here depends on first-run state, and the Library screen is
      // rebuilt from the persisted archive on every visit.
      final addButton = find.text('Add photos & videos');
      expect(addButton, findsOneWidget);

      await tester.tap(addButton);
      // The Import screen runs a periodic indexing timer, so settle
      // with plain pumps instead of pumpAndSettle.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(ImportScreen), findsOneWidget);
      expect(find.text('Everything lands here first'), findsOneWidget);
    },
  );
}
