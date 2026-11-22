import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:palimpsest/models/account.dart';
import 'package:palimpsest/models/archive_data.dart';
import 'package:palimpsest/models/memory_item.dart';
import 'package:palimpsest/models/story.dart';
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
    String? storyId,
    bool isDemo = false,
  }) =>
      MemoryItem(
        id: id,
        kind: MediaKind.photo,
        title: 'Item $id',
        takenAt: DateTime.utc(2024, 5, 12, 14, 30),
        checksum: 'checksum-$id',
        storyId: storyId,
        tags: const <String>['test'],
        aspectRatio: '4:3',
        widthPx: 800,
        heightPx: 600,
        isDemo: isDemo,
        blobId: 'blob-$id',
        thumbBlobId: 'thumb-$id',
        mimeType: 'image/jpeg',
        sourceName: '$id.jpg',
        gpsLat: 37.775,
        gpsLng: -122.4194,
      );

  Story story({required String id}) => Story(
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
        isDemo: false,
      );

  ArchiveData sampleArchive() => ArchiveData.empty().copyWith(
        stories: <Story>[story(id: 'story-1')],
        items: <MemoryItem>[
          item(id: 'item-1', storyId: 'story-1'),
          item(id: 'item-2'),
        ],
        corrections: const <String, List<String>>{
          'weekend': <String>['item-2'],
        },
        settings: const ArchiveSettings(offlineMode: true),
        importState: const ImportState(
          total: 10,
          indexed: 10,
          status: ImportStatus.done,
          sourceLabel: 'Camera roll',
        ),
        onboardingSeen: true,
      );

  group('ArchiveStore with Drift', () {
    test('load returns null when nothing is stored', () async {
      expect(await store.load(), isNull);
    });

    test('save then load round-trips the whole document', () async {
      await store.save(sampleArchive());
      final loaded = await store.load();
      expect(loaded, isNotNull);
      expect(loaded!.version, 2);
      expect(loaded.items.map((i) => i.id), <String>['item-1', 'item-2']);
      final first = loaded.items.first;
      expect(first.title, 'Item item-1');
      expect(first.checksum, 'checksum-item-1');
      expect(first.blobId, 'blob-item-1');
      expect(first.thumbBlobId, 'thumb-item-1');
      expect(first.mimeType, 'image/jpeg');
      expect(first.sourceName, 'item-1.jpg');
      expect(first.gpsLat, closeTo(37.775, 0.0001));
      expect(first.gpsLng, closeTo(-122.4194, 0.0001));
      expect(first.widthPx, 800);
      expect(first.heightPx, 600);
      expect(first.storyId, 'story-1');
      expect(loaded.stories.map((s) => s.id), <String>['story-1']);
      expect(loaded.stories.first.title, 'Story story-1');
      expect(loaded.corrections, <String, List<String>>{
        'weekend': <String>['item-2'],
      });
      expect(loaded.settings.offlineMode, isTrue);
      expect(loaded.importState.total, 10);
      expect(loaded.importState.status, ImportStatus.done);
      expect(loaded.onboardingSeen, isTrue);
    });

    test('save removes rows that left the document', () async {
      await store.save(sampleArchive());
      final smaller = sampleArchive()
          .copyWith(items: <MemoryItem>[item(id: 'item-1', storyId: 'story-1')]);
      await store.save(smaller);
      final loaded = await store.load();
      expect(loaded!.items.map((i) => i.id), <String>['item-1']);
    });

    test('save with an empty document clears every table', () async {
      await store.save(sampleArchive());
      await store.save(ArchiveData.empty());
      final loaded = await store.load();
      expect(loaded, isNotNull);
      expect(loaded!.items, isEmpty);
      expect(loaded.stories, isEmpty);
      expect(loaded.onboardingSeen, isFalse);
    });

    test('clear removes everything', () async {
      await store.save(sampleArchive());
      await store.clear();
      expect(await store.load(), isNull);
    });

    test('a corrupt row is skipped, the rest loads', () async {
      await store.save(sampleArchive());
      await db.into(db.items).insert(
            const ItemsCompanion(
              id: Value('item-broken'),
              data: Value('{not valid json'),
              takenAt: Value(0),
              kind: Value('photo'),
              isDemo: Value(false),
              storyId: Value<String?>(null),
            ),
          );
      final loaded = await store.load();
      expect(loaded, isNotNull);
      expect(
        loaded!.items.map((i) => i.id),
        <String>['item-1', 'item-2'],
      );
    });
  });
}
