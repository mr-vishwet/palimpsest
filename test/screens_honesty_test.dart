import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:palimpsest/core/routes.dart';
import 'package:palimpsest/models/account.dart';
import 'package:palimpsest/models/archive_data.dart';
import 'package:palimpsest/models/memory_item.dart';
import 'package:palimpsest/screens/ask_screen.dart';
import 'package:palimpsest/screens/home_screen.dart';
import 'package:palimpsest/screens/library_screen.dart';
import 'package:palimpsest/screens/payoff_screen.dart';
import 'package:palimpsest/screens/resurface_screen.dart';
import 'package:palimpsest/screens/settings_screen.dart';
import 'package:palimpsest/screens/timeline_screen.dart';
import 'package:palimpsest/services/archive_store.dart';
import 'package:palimpsest/state/archive_controller.dart';
import 'package:palimpsest/state/ask_controller.dart';
import 'package:palimpsest/state/auth_controller.dart';
import 'package:palimpsest/widgets/app_shell.dart';
import 'package:palimpsest/widgets/common.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_fixtures.dart';

/// A fresh archive: nothing imported, nothing seeded.
ArchiveData _emptyArchive() => ArchiveData.empty();

MemoryItem _item({
  required String id,
  required DateTime takenAt,
  MediaKind kind = MediaKind.photo,
  List<String> tags = const <String>[],
}) =>
    TestFixtures.item(
      id: id,
      kind: kind,
      title: id,
      takenAt: takenAt,
      tags: tags,
    );

Future<void> _pumpScreen(
  WidgetTester tester,
  ArchiveData data,
  Widget screen,
) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final archive = ArchiveController(store: ArchiveStore(), initialData: data);
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
        child: screen,
      ),
      onGenerateRoute: (settings) {
        if (settings.name == Routes.import) {
          return MaterialPageRoute<void>(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Import stub')),
            ),
            settings: settings,
          );
        }
        return null;
      },
    ),
  );
  // Plain pumps, not pumpAndSettle: screens with a MemoryOrb run a
  // repeating animation, so the frame queue never settles.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ArchiveCounts', () {
    test('counts the fixture library by kind', () {
      final items = TestFixtures.archive().items;
      expect(items.length, 38);
      expect(ArchiveCounts.photos(items), 30);
      expect(ArchiveCounts.videos(items), 6);
      expect(ArchiveCounts.voiceNotes(items), 1);
      expect(ArchiveCounts.notes(items), 1);
    });

    test('counts are 0 on an empty archive', () {
      const items = <MemoryItem>[];
      expect(ArchiveCounts.photos(items), 0);
      expect(ArchiveCounts.videos(items), 0);
      expect(ArchiveCounts.voiceNotes(items), 0);
      expect(ArchiveCounts.notes(items), 0);
    });
  });

  group('archiveYearSpan', () {
    test('derives the fixture span: 1992–2026, 35 years', () {
      final span = archiveYearSpan(TestFixtures.archive().items);
      expect(span, isNotNull);
      expect(span!.startYear, 1992);
      expect(span.endYear, 2026);
      expect(span.years, 35);
    });

    test('is null on an empty archive', () {
      expect(archiveYearSpan(const <MemoryItem>[]), isNull);
    });

    test('a single year spans one year', () {
      final span = archiveYearSpan(<MemoryItem>[
        _item(id: 'a', takenAt: DateTime(2024, 3, 1)),
        _item(id: 'b', takenAt: DateTime(2024, 11, 30)),
      ]);
      expect(span!.years, 1);
      expect(span.startYear, 2024);
      expect(span.endYear, 2024);
    });
  });

  group('pickResurfacedDay', () {
    test('picks the rain day for the week of 23 Nov 2026', () {
      final day = pickResurfacedDay(
        TestFixtures.archive().items,
        DateTime(2026, 11, 23),
      );
      expect(day, isNotNull);
      expect(day!.date, DateTime(2023, 11, 19));
      expect(day.items.length, 2);
      expect(day.yearsAgo(DateTime(2026, 11, 23)), 3);
      expect(day.photos, 1);
      expect(day.videos, 1);
      expect(day.sharedStoryId, 'family');
      expect(day.sharedChapterId, 'family-ch3');
    });

    test('picks the busiest day in the cruise week', () {
      final day = pickResurfacedDay(
        TestFixtures.archive().items,
        DateTime(2026, 6, 20),
      );
      expect(day, isNotNull);
      expect(day!.date, DateTime(2025, 6, 14));
      expect(day.items.length, 3);
      expect(day.yearsAgo(DateTime(2026, 6, 20)), 1);
    });

    test('returns null when nothing from a past year falls this week', () {
      expect(
        pickResurfacedDay(TestFixtures.archive().items, DateTime(2026, 2, 10)),
        isNull,
      );
    });

    test('returns null on an empty archive', () {
      expect(
        pickResurfacedDay(const <MemoryItem>[], DateTime(2026, 11, 23)),
        isNull,
      );
    });

    test('same-year items are never resurfaced', () {
      // The project weekend is 3–4 Oct 2026; asked in that same week
      // in 2026, it must not resurface — only past years count.
      expect(
        pickResurfacedDay(TestFixtures.archive().items, DateTime(2026, 10, 5)),
        isNull,
      );
    });

    test('ties go to the most recent year', () {
      final items = <MemoryItem>[
        _item(id: 'old-1', takenAt: DateTime(2020, 3, 10, 9)),
        _item(id: 'old-2', takenAt: DateTime(2020, 3, 10, 10)),
        _item(id: 'new-1', takenAt: DateTime(2024, 3, 10, 9)),
        _item(id: 'new-2', takenAt: DateTime(2024, 3, 10, 10)),
      ];
      final day = pickResurfacedDay(items, DateTime(2026, 3, 10));
      expect(day, isNotNull);
      expect(day!.date, DateTime(2024, 3, 10));
    });

    test('items are chronological within the day', () {
      final day = pickResurfacedDay(
        TestFixtures.archive().items,
        DateTime(2026, 11, 23),
      );
      expect(day!.items.first.id, 'fam-rain-1');
      expect(day.items.last.id, 'fam-rain-2');
    });
  });

  group('empty states', () {
    testWidgets('Library shows a true empty state with an import action',
        (tester) async {
      await _pumpScreen(tester, _emptyArchive(), const LibraryScreen());
      expect(find.text('Your library is empty'), findsOneWidget);
      expect(find.text('Import photos & videos'), findsWidgets);

      // The empty-state action sits below the fold in the test
      // viewport: scroll it into view before tapping.
      final action = find.text('Import photos & videos').last;
      await tester.ensureVisible(action);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(action);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Import stub'), findsOneWidget);
    });

    testWidgets('Library with content shows the frame count, no empty state',
        (tester) async {
      await _pumpScreen(tester, TestFixtures.archive(), const LibraryScreen());
      expect(find.text('Your library is empty'), findsNothing);
      expect(find.text('38 frames'), findsOneWidget);
    });

    testWidgets('Home shows an empty-archive welcome with an import action',
        (tester) async {
      await _pumpScreen(tester, _emptyArchive(), const HomeScreen());
      expect(find.text('Your archive is empty'), findsOneWidget);
      expect(find.text('Import photos & videos'), findsOneWidget);
      expect(find.text('0 items · 0 voice notes · 0 uploaded'), findsOneWidget);
      expect(
          find.text('No stories yet — save one from a reconstructed moment, '
              'or import photos to begin.'),
          findsOneWidget);
    });

    testWidgets('Home hides the resurface card when resurfacing is off',
        (tester) async {
      final data = TestFixtures.archive().copyWith(
        settings: const ArchiveSettings(resurfaceEnabled: false),
      );
      await _pumpScreen(tester, data, const HomeScreen());
      expect(find.textContaining('ago this week'), findsNothing);
    });

    testWidgets('Ask on an empty archive says to import first', (tester) async {
      await _pumpScreen(tester, _emptyArchive(), const AskScreen());
      expect(find.text('Nothing to ask about yet'), findsOneWidget);
      expect(find.text('Import photos & videos'), findsOneWidget);
      // The field starts empty: no pre-filled canonical question.
      expect(
        find.textContaining('weekend when I first started'),
        findsNothing,
      );
    });

    testWidgets('Ask derives suggestions from the archive’s own tags',
        (tester) async {
      await _pumpScreen(tester, TestFixtures.archive(), const AskScreen());
      expect(find.text('Questions that work'), findsOneWidget);
      expect(find.text('project-weekend'), findsOneWidget);
      expect(find.text('14 items tagged project-weekend'), findsOneWidget);
      // The seeded suggestions are gone.
      expect(find.text('The weekend the project started'), findsNothing);
      expect(find.text('Every birthday with Dad in it'), findsNothing);
    });

    testWidgets('Resurface on an empty archive shows its empty state',
        (tester) async {
      await _pumpScreen(tester, _emptyArchive(), const ResurfaceScreen());
      expect(find.text('Nothing to resurface this week'), findsOneWidget);
      // The toggle is still there — it gates the Home card.
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('Timeline on an empty archive shows its empty state',
        (tester) async {
      await _pumpScreen(tester, _emptyArchive(), const TimelineScreen());
      expect(find.text('No timeline yet'), findsOneWidget);
      expect(find.text('Import photos & videos'), findsOneWidget);
      expect(find.textContaining('years, newest first'), findsNothing);
    });

    testWidgets('Timeline with content shows the derived span', (tester) async {
      await _pumpScreen(tester, TestFixtures.archive(), const TimelineScreen());
      expect(find.text('35 years, newest first'), findsOneWidget);
    });
  });

  group('derived counts on screens', () {
    testWidgets('Settings shows derived counts and only two live toggles',
        (tester) async {
      await _pumpScreen(tester, TestFixtures.archive(), const SettingsScreen());
      expect(find.text('30 photos · 6 videos · 9 voice notes · 4 stories'),
          findsOneWidget);
      expect(find.text('38 items on this device · 0 uploaded'), findsOneWidget);
      // Resurface + offline are the only switches left; the four
      // dead toggles became informational rows.
      expect(find.byType(Switch), findsNWidgets(2));
      expect(find.text('Full quality'), findsOneWidget);
      expect(find.text('On-device grouping'), findsOneWidget);
      expect(find.text('Local transcription'), findsOneWidget);
    });

    testWidgets('Payoff shows derived counts', (tester) async {
      await _pumpScreen(tester, TestFixtures.archive(), const PayoffScreen());
      expect(find.text('30'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('5,012'), findsNothing);
    });
  });
}
