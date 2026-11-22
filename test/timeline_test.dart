import 'package:flutter_test/flutter_test.dart';
import 'package:palimpsest/engine/timeline.dart';

import 'test_fixtures.dart';

void main() {
  group('TimelineBuilder', () {
    final data = TestFixtures.archive();

    test('years are newest first', () {
      final years = TimelineBuilder.build(data.items, data.stories);
      final yearNumbers = years.map((y) => y.year).toList();
      expect(yearNumbers.first, 2026);
      expect(yearNumbers.last, 1990);
      for (var i = 0; i < yearNumbers.length - 1; i++) {
        expect(yearNumbers[i], greaterThan(yearNumbers[i + 1]));
      }
    });

    test('items within a year are newest first', () {
      final years = TimelineBuilder.build(data.items, data.stories);
      for (final year in years) {
        for (var i = 0; i < year.items.length - 1; i++) {
          expect(
            year.items[i].takenAt.isAfter(year.items[i + 1].takenAt) ||
                year.items[i].takenAt.isAtSameMomentAs(year.items[i + 1].takenAt),
            isTrue,
          );
        }
      }
    });

    test('stories are placed by their start year', () {
      final years = TimelineBuilder.build(data.items, data.stories);
      final byYear = {for (final y in years) y.year: y};
      expect(
        byYear[2025]!.stories.map((s) => s.id),
        containsAll(['cruise', 'moto']),
      );
      expect(byYear[2023]!.stories.map((s) => s.id), contains('family'));
      expect(
        byYear[1990]!.stories.map((s) => s.id),
        contains('childhood'),
      );
    });

    test('newestFirst and oldestFirst are exact reverses', () {
      final newest = TimelineBuilder.newestFirst(data.items);
      final oldest = TimelineBuilder.oldestFirst(data.items);
      expect(newest.first.id, oldest.last.id);
      expect(newest.last.id, oldest.first.id);
      expect(newest.length, data.items.length);
    });

    test('every item appears in exactly one year', () {
      final years = TimelineBuilder.build(data.items, data.stories);
      final counted =
          years.fold(0, (sum, year) => sum + year.items.length);
      expect(counted, data.items.length);
    });
  });
}
