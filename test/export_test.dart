import 'package:flutter_test/flutter_test.dart';
import 'package:palimpsest/engine/exporter.dart';

import 'test_fixtures.dart';

void main() {
  group('Exporter', () {
    final data = TestFixtures.archive();

    test('re-exporting a story produces identical bytes', () {
      final story = data.stories.firstWhere((s) => s.id == 'cruise');
      final first = Exporter.manifestForStory(story, data.items, data.layers);
      final second = Exporter.manifestForStory(story, data.items, data.layers);
      expect(first, second);
    });

    test('input order does not change the manifest', () {
      final story = data.stories.firstWhere((s) => s.id == 'cruise');
      final forward =
          Exporter.manifestForStory(story, data.items, data.layers);
      final reversed = Exporter.manifestForStory(
        story,
        data.items.reversed.toList(),
        data.layers.reversed.toList(),
      );
      expect(forward, reversed);
    });

    test('the manifest carries provenance for every item', () {
      final story = data.stories.firstWhere((s) => s.id == 'cruise');
      final manifest =
          Exporter.manifestForStory(story, data.items, data.layers);
      expect(manifest, contains('palimpsest-manifest'));
      expect(manifest, contains('frame-042'));
      final frame = data.items.firstWhere((i) => i.id == 'frame-042');
      expect(manifest, contains(frame.checksum));
      expect(manifest, contains('Boarding, at dusk'));
    });

    test('the moment manifest carries reasons', () {
      final moment = data.moments.first;
      final manifest = Exporter.manifestForMoment(moment, data.items);
      expect(manifest, contains('moment'));
      expect(manifest, contains('First sketch — Saturday 09:12'));
      final again = Exporter.manifestForMoment(moment, data.items);
      expect(manifest, again);
    });
  });
}
