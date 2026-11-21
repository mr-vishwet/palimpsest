import 'package:flutter_test/flutter_test.dart';
import 'package:palimpsest/core/constants.dart';
import 'package:palimpsest/engine/archive_index.dart';
import 'package:palimpsest/engine/reconstructor.dart';
import 'package:palimpsest/services/demo_seed.dart';

void main() {
  group('Reconstructor', () {
    final data = DemoSeed.build();

    test('canonical question rebuilds the project weekend', () {
      final moment = Reconstructor.reconstruct(
        AppConstants.canonicalAsk,
        data,
        now: DateTime(2026, 11, 21, 12, 40),
      );
      expect(moment.title, 'The weekend the project started');
      expect(moment.itemIds, hasLength(14));
      expect(moment.itemIds, contains('pw-01'));
      expect(moment.itemIds, contains('pw-08'));
    });

    test('items are in chronological order', () {
      final moment = Reconstructor.reconstruct(
        AppConstants.canonicalAsk,
        data,
      );
      final items = moment.itemIds.map((id) => data.items.firstWhere((i) => i.id == id)).toList();
      for (var i = 0; i < items.length - 1; i++) {
        expect(
          items[i].takenAt.isBefore(items[i + 1].takenAt) ||
              items[i].takenAt.isAtSameMomentAs(items[i + 1].takenAt),
          isTrue,
        );
      }
    });

    test('exactly two items look wrong', () {
      final moment = Reconstructor.reconstruct(
        AppConstants.canonicalAsk,
        data,
      );
      expect(moment.flaggedIds, hasLength(2));
      expect(moment.flaggedIds, containsAll(['pw-wrong-1', 'pw-wrong-2']));
    });

    test('anchor finds are the sketch, the voice note and the cut', () {
      final moment = Reconstructor.reconstruct(
        AppConstants.canonicalAsk,
        data,
      );
      final anchors = Reconstructor.anchorFinds(moment, data.items);
      expect(
        anchors.map((a) => a.label),
        [
          'First sketch — Sat 09:12',
          'First voice note — Sat 22:40',
          'First cut — Sun 18:03',
        ],
      );
    });

    test('every item carries a reason', () {
      final moment = Reconstructor.reconstruct(
        AppConstants.canonicalAsk,
        data,
      );
      for (final id in moment.itemIds) {
        expect(moment.reasons[id], isNotEmpty);
      }
      expect(moment.reasonFor('pw-01'), 'First sketch — Saturday 09:12');
    });

    test('corrections exclude removed items next time', () {
      final normalized = ArchiveIndex.normalize(AppConstants.canonicalAsk);
      final corrected = data.copyWith(
        corrections: <String, List<String>>{
          normalized: ['pw-02', 'pw-wrong-1'],
        },
      );
      final moment = Reconstructor.reconstruct(
        AppConstants.canonicalAsk,
        corrected,
      );
      expect(moment.itemIds, hasLength(12));
      expect(moment.itemIds, isNot(contains('pw-02')));
      expect(moment.itemIds, isNot(contains('pw-wrong-1')));
    });

    test('a plain question searches the index', () {
      final moment = Reconstructor.reconstruct(
        'Rain, anywhere, any year',
        data,
      );
      expect(moment.itemIds, hasLength(3));
      expect(moment.flaggedIds, isEmpty);
    });

    test('a question with no match returns an empty moment', () {
      final moment = Reconstructor.reconstruct('zxqvkj', data);
      expect(moment.itemIds, isEmpty);
      expect(moment.title, 'Zxqvkj');
    });

    test('titleFor tidies questions into moment titles', () {
      expect(
        Reconstructor.titleFor('Show me the last day of the cruise'),
        'The last day of the cruise',
      );
      expect(
        Reconstructor.titleFor('The weekend the project started'),
        'The weekend the project started',
      );
    });
  });
}
