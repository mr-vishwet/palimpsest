import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:palimpsest/engine/exporter.dart';
import 'package:palimpsest/services/blob_store.dart';
import 'package:palimpsest/services/export_delivery.dart';

import 'test_fixtures.dart';

void main() {
  group('ExportDelivery.buildZip', () {
    const manifest = '{"format":"palimpsest-manifest","version":2}';
    final media = <String, Uint8List>{
      'media/b-photo.jpg': Uint8List.fromList(<int>[1, 2, 3, 4]),
      'media/a-video.mp4': Uint8List.fromList(<int>[5, 6, 7, 8, 9]),
    };

    test('the same inputs produce identical bytes', () {
      final first = ExportDelivery.buildZip(
        manifest: manifest,
        mediaFiles: media,
      );
      final second = ExportDelivery.buildZip(
        manifest: manifest,
        mediaFiles: media,
      );
      expect(first, second);
    });

    test('input map order does not change the zip', () {
      final forward = ExportDelivery.buildZip(
        manifest: manifest,
        mediaFiles: media,
      );
      final reversed = ExportDelivery.buildZip(
        manifest: manifest,
        mediaFiles: Map<String, Uint8List>.fromEntries(
          media.entries.toList().reversed,
        ),
      );
      expect(forward, reversed);
    });

    test('the zip decodes back to the manifest and the exact media bytes', () {
      final zip = ExportDelivery.buildZip(
        manifest: manifest,
        mediaFiles: media,
      );
      final decoded = ZipDecoder().decodeBytes(zip);
      final manifestFile = decoded.findFile(ExportDelivery.manifestName);
      expect(manifestFile, isNotNull);
      expect(utf8.decode(manifestFile!.content), manifest);
      final photo = decoded.findFile('media/b-photo.jpg');
      expect(photo, isNotNull);
      expect(photo!.content, Uint8List.fromList(<int>[1, 2, 3, 4]));
      final video = decoded.findFile('media/a-video.mp4');
      expect(video, isNotNull);
      expect(video!.content, Uint8List.fromList(<int>[5, 6, 7, 8, 9]));
    });

    test('entries are sorted by path, manifest first', () {
      final zip = ExportDelivery.buildZip(
        manifest: manifest,
        mediaFiles: media,
      );
      final decoded = ZipDecoder().decodeBytes(zip);
      final names = decoded.files.map((f) => f.name).toList();
      expect(
        names,
        <String>[
          'manifest.json',
          'media/a-video.mp4',
          'media/b-photo.jpg',
        ],
      );
    });

    test('no media still yields a valid zip with just the manifest', () {
      final zip = ExportDelivery.buildZip(
        manifest: manifest,
        mediaFiles: <String, Uint8List>{},
      );
      final decoded = ZipDecoder().decodeBytes(zip);
      expect(decoded.files.length, 1);
      expect(decoded.files.single.name, 'manifest.json');
    });

    test('bytes round-trip through the blob store into the zip', () async {
      final store = MemoryBlobStore();
      final original = Uint8List.fromList(List<int>.generate(256, (i) => i));
      final blobId = await store.put(original);
      final bytes = await store.get(blobId);
      expect(bytes, original);
      final zip = ExportDelivery.buildZip(
        manifest: manifest,
        mediaFiles: <String, Uint8List>{'media/round-trip.bin': bytes!},
      );
      final decoded = ZipDecoder().decodeBytes(zip);
      expect(
        decoded.findFile('media/round-trip.bin')!.content,
        original,
      );
    });
  });

  group('ExportDelivery.extensionForMimeType', () {
    test('maps common media types', () {
      expect(ExportDelivery.extensionForMimeType('image/jpeg'), '.jpg');
      expect(ExportDelivery.extensionForMimeType('image/png'), '.png');
      expect(ExportDelivery.extensionForMimeType('video/mp4'), '.mp4');
      expect(ExportDelivery.extensionForMimeType('video/quicktime'), '.mov');
      expect(ExportDelivery.extensionForMimeType('audio/wav'), '.wav');
      expect(ExportDelivery.extensionForMimeType('audio/mpeg'), '.mp3');
    });

    test('unknown or missing types get no extension', () {
      expect(ExportDelivery.extensionForMimeType('application/x-weird'), '');
      expect(ExportDelivery.extensionForMimeType(null), '');
    });
  });

  group('Exporter manifest with media', () {
    final data = TestFixtures.archive();
    final story = data.stories.firstWhere((s) => s.id == 'cruise');
    final frame = data.items.firstWhere((i) => i.id == 'frame-042');

    Map<String, ExportMediaFile> mediaFor(String fileName) =>
        <String, ExportMediaFile>{
          frame.id: ExportMediaFile(
            fileName: fileName,
            byteSize: 1234,
            sha256: frame.checksum,
          ),
        };

    test('a media entry lands in the manifest with its checksum', () {
      final manifest = Exporter.manifestForStory(
        story,
        data.items,
        data.layers,
        mediaFiles: mediaFor('media/frame-042.jpg'),
      );
      expect(manifest, contains('media/frame-042.jpg'));
      expect(manifest, contains(frame.checksum));
      expect(manifest, contains('"byteSize": 1234'));
    });

    test('the media manifest is deterministic', () {
      final first = Exporter.manifestForStory(
        story,
        data.items,
        data.layers,
        mediaFiles: mediaFor('media/frame-042.jpg'),
      );
      final second = Exporter.manifestForStory(
        story,
        data.items.reversed.toList(),
        data.layers.reversed.toList(),
        mediaFiles: mediaFor('media/frame-042.jpg'),
      );
      expect(first, second);
    });

    test('without media there is no file key', () {
      final manifest = Exporter.manifestForStory(
        story,
        data.items,
        data.layers,
      );
      expect(manifest, isNot(contains('"file"')));
    });

    test('the moment manifest carries media too', () {
      final moment = data.moments.first;
      final visible = data.items
          .where((i) => moment.visibleItemIds.contains(i.id))
          .toList(growable: false);
      expect(visible, isNotEmpty);
      final media = <String, ExportMediaFile>{
        for (final item in visible)
          item.id: ExportMediaFile(
            fileName: 'media/${item.id}.bin',
            byteSize: 10,
            sha256: item.checksum,
          ),
      };
      final manifest = Exporter.manifestForMoment(
        moment,
        data.items,
        mediaFiles: media,
      );
      final again = Exporter.manifestForMoment(
        moment,
        data.items,
        mediaFiles: media,
      );
      expect(manifest, again);
      expect(manifest, contains('media/${visible.first.id}.bin'));
    });
  });
}
