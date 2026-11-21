import 'package:flutter_test/flutter_test.dart';
import 'package:palimpsest/models/archive_data.dart';
import 'package:palimpsest/services/demo_seed.dart';

void main() {
  group('DemoSeed', () {
    final data = DemoSeed.build();

    test('seeds four stories', () {
      expect(data.stories.map((s) => s.id),
          ['cruise', 'moto', 'family', 'childhood']);
    });

    test('chapter play times sum to the story totals', () {
      final cruise = data.stories.firstWhere((s) => s.id == 'cruise');
      expect(cruise.playSeconds, 292); // 4:52
      final moto = data.stories.firstWhere((s) => s.id == 'moto');
      expect(moto.playSeconds, 872); // 14:32
    });

    test('story headline counts match the canon', () {
      final cruise = data.stories.firstWhere((s) => s.id == 'cruise');
      expect(cruise.photoCount, 542);
      expect(cruise.videoCount, 18);
      final family = data.stories.firstWhere((s) => s.id == 'family');
      expect(family.photoCount, 1284);
      expect(family.videoCount, 37);
    });

    test('five named people cover 1,852 photos', () {
      final named = data.people.where((p) => p.isNamed).toList();
      expect(named, hasLength(5));
      expect(
        named.fold(0, (sum, p) => sum + p.photoCount),
        1852,
      );
      expect(data.people.where((p) => !p.isNamed), hasLength(1));
    });

    test('seeds nine voice notes', () {
      expect(data.voiceNotes, hasLength(9));
      final porch = data.voiceNotes.firstWhere((v) => v.id == 'voice-porch');
      expect(porch.durationSeconds, 84); // 1:24
      expect(porch.transcript, contains('drive'));
    });

    test('seeds the hero moment through the real reconstructor', () {
      expect(data.moments, hasLength(1));
      final moment = data.moments.first;
      expect(moment.title, 'The weekend the project started');
      expect(moment.itemIds, hasLength(14));
      expect(moment.flaggedIds, hasLength(2));
    });

    test('import starts paused at 842 of 1,204', () {
      expect(data.importState.total, 1204);
      expect(data.importState.indexed, 842);
      expect(data.importState.status, ImportStatus.paused);
    });

    test('Frame 042 carries three layers', () {
      final layers =
          data.layers.where((l) => l.memoryId == 'frame-042').toList();
      expect(layers, hasLength(3));
      final frame = data.items.firstWhere((i) => i.id == 'frame-042');
      expect(frame.isCover, isTrue);
      expect(frame.aspectRatio, '1.85:1');
      expect(frame.widthPx, 1920);
      expect(frame.heightPx, 1080);
    });

    test('every item checksum is deterministic', () {
      final again = DemoSeed.build();
      for (var i = 0; i < data.items.length; i++) {
        expect(data.items[i].checksum, again.items[i].checksum);
      }
    });

    test('the archive round-trips through JSON', () {
      final restored = ArchiveData.fromJson(data.toJson());
      expect(restored.version, data.version);
      expect(restored.stories.length, data.stories.length);
      expect(restored.items.length, data.items.length);
      expect(restored.layers.length, data.layers.length);
      expect(restored.people.length, data.people.length);
      expect(restored.places.length, data.places.length);
      expect(restored.voiceNotes.length, data.voiceNotes.length);
      expect(restored.moments.length, data.moments.length);
      expect(restored.moments.first.itemIds, data.moments.first.itemIds);
      expect(restored.importState.indexed, data.importState.indexed);
    });
  });
}
