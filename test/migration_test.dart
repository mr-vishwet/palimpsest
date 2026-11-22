import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:palimpsest/models/account.dart';
import 'package:palimpsest/models/archive_data.dart';
import 'package:palimpsest/models/ask_result.dart';
import 'package:palimpsest/models/layer.dart';
import 'package:palimpsest/models/memory_item.dart';
import 'package:palimpsest/models/person.dart';
import 'package:palimpsest/models/place.dart';
import 'package:palimpsest/models/share_link.dart';
import 'package:palimpsest/models/story.dart';
import 'package:palimpsest/models/voice_note.dart';
import 'package:palimpsest/services/app_database.dart';
import 'package:palimpsest/services/archive_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ArchiveStore store;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    store = ArchiveStore(database: db);
  });

  tearDown(() async {
    await db.close();
  });

  MemoryItem item({
    required String id,
    required bool isDemo,
    String? storyId,
  }) =>
      MemoryItem(
        id: id,
        kind: MediaKind.photo,
        title: 'Item $id',
        takenAt: DateTime.utc(2024, 5, 12, 14, 30),
        checksum: 'checksum-$id',
        storyId: storyId,
        isDemo: isDemo,
      );

  Story story({required String id, required bool isDemo}) => Story(
        id: id,
        title: 'Story $id',
        place: 'Test place',
        durationLabel: 'A day',
        days: 1,
        peopleCount: 1,
        chapters: const <Chapter>[],
        photoCount: 1,
        videoCount: 0,
        coverArt: 'test',
        startedAt: DateTime.utc(2024, 5, 12),
        isDemo: isDemo,
      );

  VoiceNote note({required String id, required bool isDemo}) => VoiceNote(
        id: id,
        title: 'Note $id',
        durationSeconds: 30,
        transcript: 'Hello',
        takenAt: DateTime.utc(2024, 5, 12),
        waveform: const <double>[0.1, 0.2],
        isDemo: isDemo,
      );

  /// A realistic v1 stored document: the seeded demo library plus a
  /// hand-made user item (one attached to a demo story, to prove
  /// detachment) and a user story, note and moment.
  ArchiveData v1Document() => ArchiveData(
        version: 1,
        stories: <Story>[
          story(id: 'story-demo', isDemo: true),
          story(id: 'story-mine', isDemo: false),
        ],
        items: <MemoryItem>[
          item(id: 'demo-1', isDemo: true, storyId: 'story-demo'),
          item(id: 'demo-2', isDemo: true),
          item(id: 'mine-1', isDemo: false, storyId: 'story-demo'),
          item(id: 'mine-2', isDemo: false, storyId: 'story-mine'),
        ],
        layers: <MemoryLayer>[
          MemoryLayer(
            id: 'layer-demo',
            memoryId: 'demo-1',
            kind: LayerKind.caption,
            summary: 'Caption changed',
            previousValue: 'Old',
            newValue: 'New',
            createdAt: DateTime.utc(2024, 5, 13),
            isDemo: true,
          ),
          MemoryLayer(
            id: 'layer-mine',
            memoryId: 'mine-1',
            kind: LayerKind.caption,
            summary: 'Caption changed',
            previousValue: 'Old',
            newValue: 'New',
            createdAt: DateTime.utc(2024, 5, 13),
            isDemo: false,
          ),
        ],
        people: <Person>[
          const Person(id: 'person-1', photoCount: 3, colorKey: 'blue'),
        ],
        places: <Place>[
          const Place(
            id: 'place-1',
            name: 'Home',
            storyIds: <String>['story-mine'],
            x: 0.5,
            y: 0.5,
            photoCount: 2,
          ),
        ],
        voiceNotes: <VoiceNote>[
          note(id: 'voice-demo', isDemo: true),
          note(id: 'voice-mine', isDemo: false),
        ],
        shareLinks: const <ShareLink>[],
        moments: <ReconstructedMoment>[
          ReconstructedMoment(
            id: 'moment-seed',
            query: 'the project weekend',
            title: 'Seed moment',
            createdAt: DateTime.utc(2024, 5, 13),
            itemIds: const <String>['demo-1', 'demo-2'],
            reasons: const <String, String>{
              'demo-1': 'Matches',
              'demo-2': 'Matches',
            },
            flaggedIds: const <String>[],
            rebuildMs: 12,
          ),
          ReconstructedMoment(
            id: 'moment-mine',
            query: 'my photos',
            title: 'My moment',
            createdAt: DateTime.utc(2024, 5, 13),
            itemIds: const <String>['mine-1'],
            reasons: const <String, String>{'mine-1': 'Matches'},
            flaggedIds: const <String>[],
            rebuildMs: 9,
          ),
        ],
        corrections: const <String, List<String>>{},
        account: AccountState.guest(),
        settings: const ArchiveSettings(offlineMode: true),
        importState: const ImportState(
          total: 4,
          indexed: 4,
          status: ImportStatus.done,
        ),
        onboardingSeen: true,
      );

  Future<void> storeV1(ArchiveData doc) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      ArchiveStore.storageKey: jsonEncode(doc.toJson()),
    });
  }

  group('ArchiveStore v1 migration', () {
    test('migrates a v1 document, dropping only demo content', () async {
      await storeV1(v1Document());
      final loaded = await store.load();

      expect(loaded, isNotNull);
      expect(loaded!.version, 2);
      // Only the user's items survive; the one attached to the demo
      // story is detached from it.
      expect(
        loaded.items.map((i) => i.id),
        <String>['mine-1', 'mine-2'],
      );
      expect(
        loaded.items.firstWhere((i) => i.id == 'mine-1').storyId,
        isNull,
      );
      expect(
        loaded.items.firstWhere((i) => i.id == 'mine-2').storyId,
        'story-mine',
      );
      // Only the user's story survives.
      expect(
        loaded.stories.map((s) => s.id),
        <String>['story-mine'],
      );
      // Only the user's voice note survives.
      expect(
        loaded.voiceNotes.map((v) => v.id),
        <String>['voice-mine'],
      );
      // Layers on dropped items go; layers on kept items stay.
      expect(
        loaded.layers.map((l) => l.id),
        <String>['layer-mine'],
      );
      // The seed-only moment goes; the user's moment stays.
      expect(
        loaded.moments.map((m) => m.id),
        <String>['moment-mine'],
      );
      // Reference data and settings survive untouched.
      expect(loaded.people.map((p) => p.id), <String>['person-1']);
      expect(loaded.places.map((p) => p.id), <String>['place-1']);
      expect(loaded.settings.offlineMode, isTrue);
      expect(loaded.onboardingSeen, isTrue);
    });

    test('migration persists to Drift and removes the v1 key', () async {
      await storeV1(v1Document());
      await store.load();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(ArchiveStore.storageKey), isNull);

      // A second load reads the migrated document from Drift.
      final second = await ArchiveStore(database: db).load();
      expect(second, isNotNull);
      expect(
        second!.items.map((i) => i.id),
        <String>['mine-1', 'mine-2'],
      );
      expect(second.version, 2);
    });

    test('throws for malformed JSON', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        ArchiveStore.storageKey: '{not json',
      });
      expect(
        store.load(),
        throwsA(isA<ArchiveLoadException>()),
      );
    });

    test('throws for valid JSON with the wrong shape', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        ArchiveStore.storageKey: '{"version": 1}',
      });
      expect(
        store.load(),
        throwsA(isA<ArchiveLoadException>()),
      );
    });

    test('throws for an unknown enum value', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        ArchiveStore.storageKey:
            '{"version": 1, "stories": [], "items": [], "layers": [], '
            '"people": [], "places": [], "voiceNotes": [], "shareLinks": [], '
            '"moments": [], "corrections": {}, '
            '"account": {"status": "guest", "connectedSources": []}, '
            '"settings": {"offlineMode": false}, '
            '"importState": {"total": 0, "indexed": 0, '
            '"status": "no-such-status", "sourceLabel": "Camera roll"}, '
            '"onboardingSeen": false}',
      });
      expect(
        store.load(),
        throwsA(isA<ArchiveLoadException>()),
      );
    });
  });
}
