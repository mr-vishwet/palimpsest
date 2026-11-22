import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:palimpsest/models/account.dart';
import 'package:palimpsest/models/archive_data.dart';
import 'package:palimpsest/models/ask_result.dart';
import 'package:palimpsest/models/layer.dart';
import 'package:palimpsest/models/memory_item.dart';
import 'package:palimpsest/models/place.dart';
import 'package:palimpsest/models/story.dart';
import 'package:palimpsest/models/voice_note.dart';
import 'package:palimpsest/services/app_database.dart';
import 'package:palimpsest/services/archive_store.dart';
import 'package:palimpsest/services/blob_store.dart';
import 'package:palimpsest/state/archive_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ArchiveController controller;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    controller = ArchiveController(
      store: ArchiveStore(database: db),
      initialData: ArchiveData.empty(),
      blobStore: MemoryBlobStore(),
    );
  });

  tearDown(() async {
    controller.dispose();
    // Controller persists fire-and-forget; let pending saves land
    // before closing the database.
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await db.close();
  });

  MemoryItem photoItem(String id, {String checksum = 'checksum'}) =>
      MemoryItem(
        id: id,
        kind: MediaKind.photo,
        title: 'Item $id',
        takenAt: DateTime.utc(2024, 5, 12, 14, 30),
        checksum: checksum,
        isDemo: false,
      );

  test('attachVoiceNote keeps the audio link on attach and detach', () {
    final note = VoiceNote(
      id: 'voice-1',
      title: 'Note',
      durationSeconds: 30,
      transcript: '',
      takenAt: DateTime.utc(2024, 5, 12),
      waveform: const <double>[0.1],
      blobId: 'audio-blob',
      mimeType: 'audio/wav',
      isDemo: false,
    );
    controller.addVoiceNote(
      note,
      MemoryItem(
        id: 'voice-1',
        kind: MediaKind.voiceNote,
        title: 'Note',
        takenAt: DateTime.utc(2024, 5, 12),
        checksum: 'checksum-voice-1',
        blobId: 'audio-blob',
        mimeType: 'audio/wav',
        isDemo: false,
      ),
    );

    controller.attachVoiceNote('voice-1', 'story-1');
    final attached = controller.voiceNoteById('voice-1');
    expect(attached, isNotNull);
    expect(attached!.storyId, 'story-1');
    expect(attached.blobId, 'audio-blob');
    expect(attached.mimeType, 'audio/wav');

    controller.attachVoiceNote('voice-1', null);
    final detached = controller.voiceNoteById('voice-1');
    expect(detached, isNotNull);
    expect(detached!.storyId, isNull);
    expect(detached.blobId, 'audio-blob');
    expect(detached.mimeType, 'audio/wav');
  });

  test('addImportedItems dedups by checksum', () {
    expect(
      controller.addImportedItems(
        <MemoryItem>[photoItem('a', checksum: 'same')],
      ),
      1,
    );
    expect(
      controller.addImportedItems(
        <MemoryItem>[photoItem('b', checksum: 'same')],
      ),
      0,
    );
    expect(controller.items, hasLength(1));
    expect(controller.items.first.id, 'a');
  });

  test('updateItemMedia writes back probed dimensions', () {
    controller.addImportedItems(<MemoryItem>[photoItem('a')]);
    controller.updateItemMedia(
      'a',
      durationSeconds: 42,
      widthPx: 1920,
      heightPx: 1080,
    );
    final updated = controller.itemById('a');
    expect(updated, isNotNull);
    expect(updated!.durationSeconds, 42);
    expect(updated.widthPx, 1920);
    expect(updated.heightPx, 1080);
    expect(updated.aspectRatio, '16:9');
  });

  test('addPlace and renamePlace round-trip', () {
    const place = Place(
      id: 'place-1',
      name: 'Old',
      storyIds: <String>[],
      x: 0.5,
      y: 0.5,
      photoCount: 0,
    );
    controller.addPlace(place);
    expect(controller.placeById('place-1')!.name, 'Old');

    controller.renamePlace('place-1', 'New');
    expect(controller.placeById('place-1')!.name, 'New');

    // Re-adding the same id replaces instead of duplicating.
    controller.addPlace(place.copyWith(name: 'Again'));
    expect(controller.places, hasLength(1));
    expect(controller.placeById('place-1')!.name, 'Again');
  });

  test('stored counts are recomputed from the items', () {
    // The stored document declares wrong counts (as an older build
    // would); the controller recomputes them from the items on the
    // way in.
    final local = ArchiveController(
      store: ArchiveStore(database: db),
      initialData: _countedArchive(),
      blobStore: MemoryBlobStore(),
    );
    addTearDown(local.dispose);
    final story = local.storyById('story-1')!;
    expect(story.photoCount, 3);
    expect(story.videoCount, 1);
    expect(story.peopleCount, 2);
    final chapter = story.chapters.first;
    expect(chapter.photoCount, 2);
    expect(chapter.videoCount, 1);
    // 4 s per photo + the video's 30 s.
    expect(chapter.playSeconds, 38);
    expect(story.playSeconds, 38);
  });

  test('counts update when an item is deleted', () {
    final local = ArchiveController(
      store: ArchiveStore(database: db),
      initialData: _countedArchive(),
      blobStore: MemoryBlobStore(),
    );
    addTearDown(local.dispose);
    local.deleteItem('p1');
    final story = local.storyById('story-1')!;
    expect(story.photoCount, 2);
    expect(story.chapters.first.photoCount, 1);
    expect(story.chapters.first.playSeconds, 34);
  });

  test('clearDemoData removes demo content and keeps user content',
      () async {
    final blobStore = MemoryBlobStore();
    final blobId =
        await blobStore.put(Uint8List.fromList(<int>[1, 2, 3, 4]));
    final thumbId = await blobStore.put(Uint8List.fromList(<int>[5, 6]));
    final demoPhoto = TestFixtures.item(
      id: 'demo-photo',
      kind: MediaKind.photo,
      title: 'Demo',
      takenAt: DateTime.utc(2024, 1, 1),
      isDemo: true,
    ).copyWith(blobId: blobId, thumbBlobId: thumbId);
    final data = ArchiveData(
      version: 2,
      stories: <Story>[
        Story(
          id: 'story-demo',
          title: 'Demo story',
          place: 'Nowhere',
          durationLabel: 'A day',
          days: 1,
          peopleCount: 0,
          chapters: <Chapter>[
            const Chapter(
              id: 'story-demo-ch1',
              storyId: 'story-demo',
              title: 'One',
              caption: '',
              day: 1,
              photoCount: 1,
              videoCount: 0,
              playSeconds: 4,
              order: 0,
            ),
          ],
          photoCount: 1,
          videoCount: 0,
          coverArt: 'moment',
          startedAt: DateTime.utc(2024, 1, 1),
          isDemo: true,
        ),
        Story(
          id: 'story-mine',
          title: 'My story',
          place: 'Home',
          durationLabel: 'A day',
          days: 1,
          peopleCount: 0,
          chapters: <Chapter>[
            const Chapter(
              id: 'story-mine-ch1',
              storyId: 'story-mine',
              title: 'One',
              caption: '',
              day: 1,
              photoCount: 0,
              videoCount: 0,
              playSeconds: 0,
              order: 0,
              // The cover points at a demo item: clearing must clear
              // it rather than leave a dangling reference.
              coverFrameId: 'demo-photo',
            ),
          ],
          photoCount: 0,
          videoCount: 0,
          coverArt: 'moment',
          startedAt: DateTime.utc(2024, 1, 2),
          isDemo: false,
        ),
      ],
      items: <MemoryItem>[
        demoPhoto,
        TestFixtures.item(
          id: 'demo-video',
          kind: MediaKind.video,
          title: 'Demo video',
          takenAt: DateTime.utc(2024, 1, 1, 1),
          storyId: 'story-demo',
          chapterId: 'story-demo-ch1',
          isDemo: true,
        ),
        TestFixtures.item(
          id: 'mine-photo',
          kind: MediaKind.photo,
          title: 'Mine',
          takenAt: DateTime.utc(2024, 1, 2),
          storyId: 'story-mine',
          chapterId: 'story-mine-ch1',
        ),
      ],
      layers: <MemoryLayer>[
        MemoryLayer(
          id: 'layer-demo',
          memoryId: 'demo-photo',
          kind: LayerKind.caption,
          summary: 'Caption changed',
          previousValue: '',
          newValue: 'Demo',
          createdAt: DateTime.utc(2024, 1, 1),
          isDemo: true,
        ),
        MemoryLayer(
          id: 'layer-mine',
          memoryId: 'mine-photo',
          kind: LayerKind.caption,
          summary: 'Caption changed',
          previousValue: '',
          newValue: 'Mine',
          createdAt: DateTime.utc(2024, 1, 2),
          isDemo: false,
        ),
      ],
      people: const [],
      places: const [],
      voiceNotes: <VoiceNote>[
        VoiceNote(
          id: 'voice-demo',
          title: 'Demo note',
          durationSeconds: 10,
          transcript: '',
          takenAt: DateTime.utc(2024, 1, 1),
          waveform: const <double>[0.1],
          isDemo: true,
        ),
        VoiceNote(
          id: 'voice-mine',
          title: 'My note',
          durationSeconds: 10,
          transcript: '',
          takenAt: DateTime.utc(2024, 1, 2),
          waveform: const <double>[0.1],
          isDemo: false,
        ),
      ],
      shareLinks: const [],
      moments: <ReconstructedMoment>[
        ReconstructedMoment(
          id: 'moment-demo',
          query: 'demo',
          title: 'Demo',
          createdAt: DateTime.utc(2024, 1, 1),
          itemIds: const ['demo-photo', 'demo-video'],
          reasons: const <String, String>{},
          flaggedIds: const [],
          rebuildMs: 1,
        ),
        ReconstructedMoment(
          id: 'moment-mixed',
          query: 'mixed',
          title: 'Mixed',
          createdAt: DateTime.utc(2024, 1, 2),
          itemIds: const ['demo-photo', 'mine-photo'],
          reasons: const <String, String>{},
          flaggedIds: const [],
          rebuildMs: 1,
        ),
      ],
      corrections: const <String, List<String>>{},
      account: AccountState.guest(),
      settings: const ArchiveSettings(),
      importState: const ImportState(
        total: 0,
        indexed: 0,
        status: ImportStatus.idle,
      ),
      onboardingSeen: true,
    );
    final local = ArchiveController(
      store: ArchiveStore(database: db),
      initialData: data,
      blobStore: blobStore,
    );
    addTearDown(local.dispose);

    expect(local.demoItemCount, 2);
    expect(local.clearDemoData(), 2);
    // Blob cleanup is fire-and-forget; let it land.
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(local.items.map((i) => i.id), ['mine-photo']);
    expect(local.hasDemoData, isFalse);
    expect(local.stories.map((s) => s.id), ['story-mine']);
    expect(
      local.storyById('story-mine')!.chapters.first.coverFrameId,
      isNull,
    );
    expect(local.layers.map((l) => l.id), ['layer-mine']);
    expect(local.voiceNotes.map((v) => v.id), ['voice-mine']);
    expect(local.moments.map((m) => m.id), ['moment-mixed']);
    expect(await blobStore.get(blobId), isNull);
    expect(await blobStore.get(thumbId), isNull);
  });
}

/// An archive whose stored counts are deliberately wrong: one story
/// with a chapter holding 2 photos + 1 thirty-second video, plus one
/// unplaced photo in the story.
ArchiveData _countedArchive() => ArchiveData(
      version: 2,
      stories: <Story>[
        Story(
          id: 'story-1',
          title: 'Trip',
          place: 'Somewhere',
          durationLabel: 'A weekend',
          days: 2,
          peopleCount: 99,
          chapters: <Chapter>[
            const Chapter(
              id: 'story-1-ch1',
              storyId: 'story-1',
              title: 'Day one',
              caption: '',
              day: 1,
              photoCount: 99,
              videoCount: 99,
              playSeconds: 999,
              order: 0,
            ),
          ],
          photoCount: 99,
          videoCount: 99,
          coverArt: 'moment',
          startedAt: DateTime.utc(2024, 5, 12),
          isDemo: false,
        ),
      ],
      items: <MemoryItem>[
        TestFixtures.item(
          id: 'p1',
          kind: MediaKind.photo,
          title: 'P1',
          takenAt: DateTime.utc(2024, 5, 12, 10),
          storyId: 'story-1',
          chapterId: 'story-1-ch1',
          personIds: const ['dad'],
        ),
        TestFixtures.item(
          id: 'p2',
          kind: MediaKind.photo,
          title: 'P2',
          takenAt: DateTime.utc(2024, 5, 12, 11),
          storyId: 'story-1',
          chapterId: 'story-1-ch1',
          personIds: const ['mum'],
        ),
        TestFixtures.item(
          id: 'v1',
          kind: MediaKind.video,
          title: 'V1',
          takenAt: DateTime.utc(2024, 5, 12, 12),
          storyId: 'story-1',
          chapterId: 'story-1-ch1',
          durationSeconds: 30,
        ),
        TestFixtures.item(
          id: 'p3',
          kind: MediaKind.photo,
          title: 'P3',
          takenAt: DateTime.utc(2024, 5, 12, 13),
          storyId: 'story-1',
        ),
      ],
      layers: const [],
      people: const [],
      places: const [],
      voiceNotes: const [],
      shareLinks: const [],
      moments: const [],
      corrections: const <String, List<String>>{},
      account: AccountState.guest(),
      settings: const ArchiveSettings(),
      importState: const ImportState(
        total: 0,
        indexed: 0,
        status: ImportStatus.idle,
      ),
      onboardingSeen: true,
    );
