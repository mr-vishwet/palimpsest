import 'package:flutter_test/flutter_test.dart';
import 'package:palimpsest/engine/archive_index.dart';
import 'package:palimpsest/models/memory_item.dart';
import 'package:palimpsest/services/demo_seed.dart';

void main() {
  group('ArchiveIndex', () {
    final data = DemoSeed.build();
    late ArchiveIndex index;

    setUp(() {
      index = ArchiveIndex(
        items: data.items,
        voiceNotes: data.voiceNotes,
        people: data.people,
        places: data.places,
        stories: data.stories,
      );
    });

    test('tokenize drops stopwords and short tokens', () {
      expect(
        ArchiveIndex.tokenize(
          'Show me everything from the weekend when I started',
        ),
        ['everything', 'weekend'],
      );
    });

    test('tag matches score above title-only matches', () {
      final hits = index.search('rain');
      expect(hits, hasLength(3));
      expect(
        hits.map((h) => h.item.id),
        containsAll(['moto-03', 'fam-rain-1', 'fam-rain-2']),
      );
      for (final hit in hits) {
        expect(hit.item.tags, contains('rain'));
        expect(hit.score, greaterThan(ArchiveIndex.weakThreshold));
      }
    });

    test('person names match, title matches rank first', () {
      final hits = index.search('Dad');
      expect(hits.length, greaterThanOrEqualTo(5));
      // 'Birthday with Dad' matches by person AND title — top hit.
      expect(hits.first.item.id, 'kid-02');
    });

    test('birthday finds both birthday photos, newest first', () {
      final hits = index.search('birthday');
      expect(hits.map((h) => h.item.id), ['kid-03', 'kid-02']);
    });

    test('kind filter narrows to videos', () {
      final hits = index.search('', kind: MediaKind.video);
      expect(hits, isNotEmpty);
      expect(
        hits.every((h) => h.item.kind == MediaKind.video),
        isTrue,
      );
    });

    test('aspect-ratio filter narrows to 1.85:1', () {
      final hits = index.search('', aspectRatio: '1.85:1');
      expect(hits, isNotEmpty);
      expect(
        hits.every((h) => h.item.aspectRatio == '1.85:1'),
        isTrue,
      );
    });

    test('story filter narrows to one story', () {
      final hits = index.search('', storyId: 'cruise');
      expect(hits, hasLength(8));
      expect(
        hits.every((h) => h.item.storyId == 'cruise'),
        isTrue,
      );
    });

    test('no match returns an empty list', () {
      expect(index.search('zxqvkj'), isEmpty);
    });

    test('empty query with no filters returns the whole library', () {
      expect(index.search(''), hasLength(data.items.length));
    });

    test('voice-note transcripts are searchable', () {
      final notes = index.searchVoiceNotes('drive');
      expect(notes.map((n) => n.id), contains('voice-porch'));
    });

    test('results are deterministic across calls', () {
      final first = index.search('rain').map((h) => h.item.id).toList();
      final second = index.search('rain').map((h) => h.item.id).toList();
      expect(first, second);
    });
  });
}
