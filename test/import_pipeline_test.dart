import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:palimpsest/models/memory_item.dart';
import 'package:palimpsest/services/blob_store.dart';
import 'package:palimpsest/services/import_service.dart';
import 'package:palimpsest/services/media_metadata.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// A solid-colour JPEG of the given size.
  Uint8List jpeg({int width = 800, int height = 600}) {
    final image = img.Image(width: width, height: height);
    img.fill(image, color: img.ColorRgb8(200, 40, 40));
    return img.encodeJpg(image);
  }

  /// A JPEG carrying EXIF capture date + GPS (San Francisco).
  Uint8List jpegWithExif() {
    final image = img.Image(width: 64, height: 48);
    img.fill(image, color: img.ColorRgb8(40, 120, 200));
    final ifd0 = image.exif.imageIfd;
    ifd0.sub['exif'][0x9003] =
        img.IfdValueAscii('2024:05:12 14:30:00');
    final gps = ifd0.sub['gps'];
    gps[0x0001] = img.IfdValueAscii('N');
    gps[0x0002] = img.IfdValueRational.list(
      <img.Rational>[
        img.Rational(37, 1),
        img.Rational(46, 1),
        img.Rational(30, 1),
      ],
    );
    gps[0x0003] = img.IfdValueAscii('W');
    gps[0x0004] = img.IfdValueRational.list(
      <img.Rational>[
        img.Rational(122, 1),
        img.Rational(25, 1),
        img.Rational(10, 1),
      ],
    );
    return img.encodeJpg(image);
  }

  group('ImportService', () {
    late MemoryBlobStore blobs;
    late ImportService service;

    setUp(() {
      blobs = MemoryBlobStore();
      service = ImportService(blobs: blobs);
    });

    test('imports a photo: hash, blobs, thumbnail, metadata', () async {
      final bytes = jpeg();
      final result = await service.importFiles(
        <ImportFileInput>[
          ImportFileInput(name: 'IMG_0421.jpg', bytes: bytes),
        ],
      );

      expect(result.failures, isEmpty);
      expect(result.imported, hasLength(1));
      final item = result.imported.first;
      expect(item.kind, MediaKind.photo);
      expect(item.checksum, sha256.convert(bytes).toString());
      expect(item.title, 'IMG 0421');
      expect(item.sourceName, 'IMG_0421.jpg');
      expect(item.mimeType, 'image/jpeg');
      expect(item.isDemo, isFalse);
      expect(item.widthPx, 800);
      expect(item.heightPx, 600);
      expect(item.aspectRatio, '4:3');
      // The original bytes round-trip through the blob store.
      expect(item.blobId, isNotNull);
      expect(await blobs.get(item.blobId!), bytes);
      // The thumbnail exists and is a 512px JPEG.
      expect(item.thumbBlobId, isNotNull);
      final thumb = await blobs.get(item.thumbBlobId!);
      expect(thumb, isNotNull);
      final decodedThumb = img.decodeImage(thumb!);
      expect(decodedThumb, isNotNull);
      expect(decodedThumb!.width, 512);
      expect(decodedThumb.height, 384);
    });

    test('reads EXIF capture date and GPS', () async {
      final result = await service.importFiles(
        <ImportFileInput>[
          ImportFileInput(name: 'sf.jpg', bytes: jpegWithExif()),
        ],
      );

      expect(result.failures, isEmpty);
      final item = result.imported.first;
      expect(item.takenAt, DateTime(2024, 5, 12, 14, 30));
      expect(item.gpsLat, closeTo(37.775, 0.001));
      expect(item.gpsLng, closeTo(-122.4194, 0.001));
      expect(item.tags, containsAll(<String>['2024', 'may']));
    });

    test('imports a video without probing it', () async {
      final bytes = Uint8List.fromList(List<int>.generate(1024, (i) => i % 256));
      final result = await service.importFiles(
        <ImportFileInput>[
          ImportFileInput(name: 'clip.mp4', bytes: bytes),
        ],
      );

      expect(result.failures, isEmpty);
      final item = result.imported.first;
      expect(item.kind, MediaKind.video);
      expect(item.mimeType, 'video/mp4');
      // Duration/dimensions come from the player on first playback.
      expect(item.durationSeconds, isNull);
      expect(item.widthPx, 0);
      expect(item.thumbBlobId, isNull);
      expect(await blobs.get(item.blobId!), bytes);
    });

    test('a bad file skips with a reason, never aborts the batch',
        () async {
      final result = await service.importFiles(
        <ImportFileInput>[
          ImportFileInput(name: 'notes.txt', bytes: Uint8List(16)),
          ImportFileInput(name: 'good.jpg', bytes: jpeg(width: 32, height: 32)),
          ImportFileInput(name: 'empty.jpg', bytes: Uint8List(0)),
        ],
      );

      expect(result.imported, hasLength(1));
      expect(result.imported.first.sourceName, 'good.jpg');
      expect(result.failures, hasLength(2));
      expect(result.failures[0].name, 'notes.txt');
      expect(result.failures[0].reason, contains('Unsupported'));
      expect(result.failures[1].name, 'empty.jpg');
      expect(result.allSucceeded, isFalse);
    });

    test('reports per-file progress', () async {
      final seen = <int>[];
      await service.importFiles(
        <ImportFileInput>[
          ImportFileInput(name: 'a.jpg', bytes: jpeg(width: 16, height: 16)),
          ImportFileInput(name: 'b.jpg', bytes: jpeg(width: 16, height: 16)),
        ],
        onProgress: (done, total, _) {
          expect(total, 2);
          seen.add(done);
        },
      );
      expect(seen, <int>[0, 1, 2]);
    });

    test('demo-media imports are labelled demo', () async {
      final result = await service.importFiles(
        <ImportFileInput>[
          ImportFileInput(name: 'demo.jpg', bytes: jpeg(width: 16, height: 16)),
        ],
        isDemo: true,
      );
      expect(result.imported.first.isDemo, isTrue);
    });

    test('identical bytes get identical checksums and blob ids', () async {
      final bytes = jpeg(width: 16, height: 16);
      final first = await service.importFiles(
        <ImportFileInput>[ImportFileInput(name: 'one.jpg', bytes: bytes)],
      );
      final second = await service.importFiles(
        <ImportFileInput>[ImportFileInput(name: 'two.jpg', bytes: bytes)],
      );
      expect(
        second.imported.first.checksum,
        first.imported.first.checksum,
      );
      expect(
        second.imported.first.blobId,
        first.imported.first.blobId,
      );
      expect(
        second.imported.first.thumbBlobId,
        first.imported.first.thumbBlobId,
      );
      // Nothing is stored twice (content addressing): the second
      // import adds zero bytes.
      final afterFirst = await blobs.totalBytes();
      await service.importFiles(
        <ImportFileInput>[ImportFileInput(name: 'three.jpg', bytes: bytes)],
      );
      expect(await blobs.totalBytes(), afterFirst);
    });

    test('folder name becomes a tag', () async {
      final result = await service.importFiles(
        <ImportFileInput>[
          ImportFileInput(
            name: 'pic.jpg',
            bytes: jpeg(width: 16, height: 16),
            folder: 'Family Trip',
          ),
        ],
      );
      expect(result.imported.first.tags, contains('family trip'));
    });
  });

  group('MediaMetadataReader', () {
    test('makeThumbnail returns null for non-images', () {
      expect(
        MediaMetadataReader.makeThumbnail(Uint8List.fromList(<int>[1, 2, 3])),
        isNull,
      );
    });

    test('makeThumbnail does not upscale a small image', () {
      final thumb = MediaMetadataReader.makeThumbnail(
        jpeg(width: 64, height: 48),
      );
      expect(thumb, isNotNull);
      final decoded = img.decodeImage(thumb!);
      expect(decoded!.width, 64);
      expect(decoded.height, 48);
    });

    test('readImage never throws on garbage', () async {
      final metadata = await MediaMetadataReader.readImage(
        Uint8List.fromList(<int>[0, 1, 2, 3, 4, 5]),
      );
      expect(metadata.takenAt, isNull);
      expect(metadata.widthPx, isNull);
    });
  });

  group('MemoryBlobStore', () {
    test('put/get/delete/totalBytes', () async {
      final store = MemoryBlobStore();
      final bytes = Uint8List.fromList(<int>[1, 2, 3, 4]);
      final id = await store.put(bytes);
      expect(id, BlobStore.idFor(bytes));
      expect(await store.get(id), bytes);
      expect(await store.get('missing'), isNull);
      expect(await store.totalBytes(), 4);
      await store.delete(id);
      expect(await store.get(id), isNull);
      expect(await store.totalBytes(), 0);
    });
  });
}
