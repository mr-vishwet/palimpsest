/// Demo-media tests — VM ONLY, not `--platform chrome`.
///
/// The loader reads the bundled media through `rootBundle`, and the
/// EXIF fixtures load through `dart:io`: both hang (or don't exist)
/// under the Chrome test runner, which never serves unit-test assets.
/// The import pipeline itself is proven under dart2js by
/// `import_pipeline_test.dart` (Chrome 12/12); the loader is a thin
/// wrapper over it, and the real proof is the live site's first run.
library;

import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:palimpsest/models/archive_data.dart';
import 'package:palimpsest/models/memory_item.dart';
import 'package:palimpsest/services/app_database.dart';
import 'package:palimpsest/services/archive_store.dart';
import 'package:palimpsest/services/blob_store.dart';
import 'package:palimpsest/services/import_service.dart';
import 'package:palimpsest/state/archive_controller.dart';
import 'package:palimpsest/widgets/common.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ArchiveController controller;
  late MemoryBlobStore blobs;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    blobs = MemoryBlobStore();
    controller = ArchiveController(
      store: ArchiveStore(database: db),
      initialData: ArchiveData.empty(),
      blobStore: blobs,
    );
  });

  tearDown(() async {
    controller.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await db.close();
  });

  group('DemoMediaLoader', () {
    test('loads the real demo media through the import pipeline',
        () async {
      final result = await controller.loadDemoMedia();

      expect(result.failures, isEmpty);
      expect(result.loaded, 30);
      expect(result.skipped, 0);
      expect(controller.items, hasLength(30));
      expect(controller.demoItemCount, 30);
      expect(controller.hasDemoData, isTrue);
      expect(ArchiveCounts.photos(controller.items), 26);
      expect(ArchiveCounts.videos(controller.items), 4);

      // Every item is flagged demo, has a real byte checksum, and
      // every photo has a generated thumbnail.
      for (final item in controller.items) {
        expect(item.isDemo, isTrue);
        expect(item.blobId, isNotNull);
        final bytes = await blobs.get(item.blobId!);
        expect(bytes, isNotNull);
        expect(item.checksum, sha256.convert(bytes!).toString());
        if (item.kind == MediaKind.photo) {
          expect(item.thumbBlobId, isNotNull);
          expect(item.widthPx, greaterThan(0));
          expect(item.heightPx, greaterThan(0));
          final thumb = await blobs.get(item.thumbBlobId!);
          expect(thumb, isNotNull);
          expect(thumb!.length, greaterThan(0));
        }
      }
    });

    test('re-loading demo media is a no-op (dedup by checksum)',
        () async {
      final first = await controller.loadDemoMedia();
      expect(first.loaded, 30);

      final second = await controller.loadDemoMedia();
      expect(second.loaded, 0);
      expect(second.skipped, 30);
      expect(second.failures, isEmpty);
      expect(controller.items, hasLength(30));
    });

    test('demo photos without EXIF dates fall back to import time',
        () async {
      // The bundled demo photos carry technical EXIF but no capture
      // date, so takenAt is the import moment — recent, never null,
      // never a made-up date.
      final before = DateTime.now().subtract(const Duration(minutes: 1));
      await controller.loadDemoMedia();
      final after = DateTime.now().add(const Duration(minutes: 1));
      for (final item in controller.items) {
        expect(item.takenAt.isAfter(before), isTrue);
        expect(item.takenAt.isBefore(after), isTrue);
      }
    });
  });

  group('EXIF fixtures', () {
    Future<MemoryItem> importFixture(String fileName) async {
      // The demo photos have no capture dates or GPS, so these
      // synthetic fixtures (800×600, DateTimeOriginal 2024-05-12
      // 14:30:00, 51.5°N 0.12°W) prove the EXIF path end to end.
      final bytes =
          await File('test/fixtures/$fileName').readAsBytes();
      final importer = ImportService(blobs: blobs);
      final result = await importer.importFiles(
        <ImportFileInput>[
          ImportFileInput(name: fileName, bytes: bytes),
        ],
      );
      expect(result.failures, isEmpty);
      expect(result.imported, hasLength(1));
      final item = result.imported.first;
      expect(item.checksum, sha256.convert(bytes).toString());
      return item;
    }

    test('the pipeline reads capture date, GPS and dimensions',
        () async {
      // Camera-style: DateTimeOriginal in the EXIF IFD.
      final item = await importFixture('exif-sample.jpg');
      expect(item.takenAt, DateTime(2024, 5, 12, 14, 30));
      expect(item.gpsLat, closeTo(51.5, 0.0001));
      expect(item.gpsLng, closeTo(-0.12, 0.0001));
      expect(item.widthPx, 800);
      expect(item.heightPx, 600);
      expect(item.thumbBlobId, isNotNull);
    });

    test('a DateTimeOriginal in IFD0 is read too', () async {
      // Some writers (PIL, image tools) put DateTimeOriginal in
      // IFD0 instead of the EXIF IFD; the reader falls back to it.
      final item = await importFixture('exif-ifd0-sample.jpg');
      expect(item.takenAt, DateTime(2024, 5, 12, 14, 30));
      expect(item.gpsLat, closeTo(51.5, 0.0001));
      expect(item.gpsLng, closeTo(-0.12, 0.0001));
      expect(item.widthPx, 800);
      expect(item.heightPx, 600);
      expect(item.thumbBlobId, isNotNull);
    });
  });
}
