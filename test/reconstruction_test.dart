import 'package:flutter_test/flutter_test.dart';
import 'package:palimpsest/engine/archive_index.dart';
import 'package:palimpsest/engine/reconstructor.dart';

import 'test_fixtures.dart';

void main() {
  group('Reconstructor', () {
    final data = TestFixtures.archive();

    test('a question matching many items returns them all', () {
      // No special case: 'project weekend' matches the 14 items
      // tagged `project-weekend` through the plain index (partial
      // tag matches plus the weekend bonus, score 5 each) — and
      // the `weekend` token also matches every other item taken on
      // a Saturday or Sunday (score 1 each, flagged as weak).
      final moment = Reconstructor.reconstruct(
        'project weekend',
        data,
        now: DateTime(2026, 11, 21, 12, 40),
      );
      expect(moment.title, 'Project weekend');
      expect(moment.itemIds, hasLength(26));
      expect(moment.itemIds, contains('pw-01'));
      expect(moment.itemIds, contains('pw-08'));
      expect(moment.flaggedIds, hasLength(12));
      expect(moment.flaggedIds, contains('moto-03'));
      expect(moment.flaggedIds, isNot(contains('pw-01')));
    });

    test('items are in chronological order', () {
      final moment = Reconstructor.reconstruct(
        'project weekend',
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

    test('weak matches are flagged as possibly wrong', () {
      // 'moto' matches the two Moto Trip items only via the story
      // title (score 1 each) — below the weak threshold, so both
      // are flagged as looking wrong.
      final moment = Reconstructor.reconstruct('moto', data);
      expect(moment.itemIds, hasLength(2));
      expect(moment.flaggedIds, hasLength(2));
      expect(moment.flaggedIds, containsAll(['moto-03', 'moto-01']));
    });

    test('anchor finds are the sketch, the voice note and the cut', () {
      final moment = Reconstructor.reconstruct(
        'sketch voice cut',
        data,
      );
      expect(moment.itemIds, hasLength(3));
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
        'sketch voice cut',
        data,
      );
      for (final id in moment.itemIds) {
        expect(moment.reasons[id], isNotEmpty);
      }
      expect(moment.reasonFor('pw-01'), "Tagged 'sketch'");
    });

    test('corrections exclude removed items next time', () {
      final normalized = ArchiveIndex.normalize('project weekend');
      final corrected = data.copyWith(
        corrections: <String, List<String>>{
          normalized: ['pw-02', 'pw-08'],
        },
      );
      final moment = Reconstructor.reconstruct(
        'project weekend',
        corrected,
      );
      expect(moment.itemIds, hasLength(24));
      expect(moment.itemIds, isNot(contains('pw-02')));
      expect(moment.itemIds, isNot(contains('pw-08')));
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

    test('a question of only stopwords returns an empty moment', () {
      // 'what', 'was' and 'that' are all stopwords, so the question
      // carries no searchable words. The index answers an empty
      // token list with the whole library (right for library
      // browsing), but a reconstruction must match nothing — the
      // moment screen's 'Nothing matched' state, not the entire
      // library flagged as looking wrong.
      final moment = Reconstructor.reconstruct('what was that', data);
      expect(moment.itemIds, isEmpty);
      expect(moment.flaggedIds, isEmpty);
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
