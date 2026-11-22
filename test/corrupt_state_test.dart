import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:palimpsest/screens/corrupt_state_screen.dart';
import 'package:palimpsest/services/app_database.dart';
import 'package:palimpsest/services/archive_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ArchiveStore.load failure modes', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('an empty store loads null (first run)', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final store = ArchiveStore(database: db);
      expect(await store.load(), isNull);
    });

    test('a v1 document that is not JSON throws', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        ArchiveStore.storageKey: 'this is not json at all',
      });
      final store = ArchiveStore(database: db);
      expect(
        store.load(),
        throwsA(isA<ArchiveLoadException>()),
      );
    });

    test('a v1 document of the wrong shape throws', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        ArchiveStore.storageKey: '["an", "array", "not", "a", "document"]',
      });
      final store = ArchiveStore(database: db);
      expect(
        store.load(),
        throwsA(isA<ArchiveLoadException>()),
      );
    });

    test('a v1 document missing its fields throws', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        ArchiveStore.storageKey: '{"version": 1}',
      });
      final store = ArchiveStore(database: db);
      expect(
        store.load(),
        throwsA(isA<ArchiveLoadException>()),
      );
    });

    test('an unreachable database throws instead of reporting no archive',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      // A LazyDatabase whose opener throws stands in for an
      // unreachable database: the read fails, and load() must
      // throw — never return null, or the caller would persist an
      // empty archive over the data.
      final failing = AppDatabase.forTesting(
        LazyDatabase(() async => throw StateError('unreachable')),
      );
      // Closing re-runs the failing opener, so guard it: the close
      // itself is best-effort cleanup, not part of the assertion.
      addTearDown(() async {
        try {
          await failing.close();
        } catch (_) {}
      });
      final store = ArchiveStore(database: failing);
      expect(
        store.load(),
        throwsA(isA<ArchiveLoadException>()),
      );
    });
  });

  group('CorruptStateScreen', () {
    testWidgets('Try again calls onRetry', (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      var retried = false;
      await tester.pumpWidget(
        MaterialApp(
          home: CorruptStateScreen(
            detail: 'The local archive database could not be read.',
            onRetry: () => retried = true,
            onStartFresh: () {},
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Your archive couldn’t be opened'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      expect(retried, isTrue);
    });

    testWidgets('Start fresh confirms before calling onStartFresh',
        (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      var startedFresh = false;
      await tester.pumpWidget(
        MaterialApp(
          home: CorruptStateScreen(
            detail: 'The stored archive could not be read.',
            onRetry: () {},
            onStartFresh: () => startedFresh = true,
          ),
        ),
      );
      await tester.pump();

      // Cancel path: nothing happens.
      await tester.tap(find.text('Start fresh — delete the stored archive'));
      await tester.pump();
      expect(find.text('Delete the stored archive?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      expect(startedFresh, isFalse);

      // Confirm path: the callback fires.
      await tester.tap(find.text('Start fresh — delete the stored archive'));
      await tester.pump();
      await tester.tap(find.text('Delete everything'));
      await tester.pump();
      expect(startedFresh, isTrue);
    });
  });
}
