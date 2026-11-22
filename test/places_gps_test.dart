import 'package:flutter_test/flutter_test.dart';
import 'package:palimpsest/models/place.dart';
import 'package:palimpsest/services/place_clustering.dart';

void main() {
  group('PlaceClusterer.cluster', () {
    test('empty input clusters to nothing', () {
      expect(PlaceClusterer.cluster(<GpsPoint>[]), isEmpty);
    });

    test('a single point is its own cluster, centred on itself', () {
      final clusters = PlaceClusterer.cluster(<GpsPoint>[
        const GpsPoint(lat: 48.85, lng: 2.35, itemId: 'a'),
      ]);
      expect(clusters.length, 1);
      expect(clusters.first.count, 1);
      expect(clusters.first.centerLat, 48.85);
      expect(clusters.first.centerLng, 2.35);
      expect(clusters.first.itemIds, <String>['a']);
    });

    test('nearby points cluster together', () {
      // All three sit inside one 0.01° cell (48.85–48.86, 2.35–2.36).
      final clusters = PlaceClusterer.cluster(<GpsPoint>[
        const GpsPoint(lat: 48.851, lng: 2.351, itemId: 'a'),
        const GpsPoint(lat: 48.852, lng: 2.352, itemId: 'b'),
        const GpsPoint(lat: 48.853, lng: 2.353, itemId: 'c'),
      ]);
      expect(clusters.length, 1);
      expect(clusters.first.count, 3);
      expect(clusters.first.centerLat, closeTo(48.852, 0.001));
      expect(clusters.first.centerLng, closeTo(2.352, 0.001));
    });

    test('points a city apart stay separate', () {
      final clusters = PlaceClusterer.cluster(<GpsPoint>[
        const GpsPoint(lat: 48.85, lng: 2.35, itemId: 'paris'),
        const GpsPoint(lat: 51.50, lng: -0.12, itemId: 'london'),
      ]);
      expect(clusters.length, 2);
      expect(
        clusters.map((c) => c.itemIds.single).toSet(),
        <String>{'paris', 'london'},
      );
    });

    test('invalid coordinates are ignored', () {
      final clusters = PlaceClusterer.cluster(<GpsPoint>[
        const GpsPoint(lat: double.nan, lng: 2.35, itemId: 'nan'),
        const GpsPoint(lat: 100, lng: 2.35, itemId: 'too-far-north'),
        const GpsPoint(lat: 48.85, lng: 200, itemId: 'too-far-east'),
        const GpsPoint(lat: 48.85, lng: 2.35, itemId: 'good'),
      ]);
      expect(clusters.length, 1);
      expect(clusters.first.itemIds, <String>['good']);
    });

    test('clustering is deterministic: same points, same ids, same order', () {
      List<GpsCluster> run() => PlaceClusterer.cluster(<GpsPoint>[
            const GpsPoint(lat: 48.85, lng: 2.35, itemId: 'a'),
            const GpsPoint(lat: 51.50, lng: -0.12, itemId: 'b'),
            const GpsPoint(lat: 48.851, lng: 2.351, itemId: 'c'),
          ]);
      final first = run().map((c) => c.id).toList();
      final second = run().map((c) => c.id).toList();
      expect(first, second);
      expect(first, orderedEquals(first..sort()));
    });

    test('story ids are collected and sorted', () {
      final clusters = PlaceClusterer.cluster(<GpsPoint>[
        const GpsPoint(
          lat: 48.851,
          lng: 2.351,
          itemId: 'a',
          storyId: 'story-z',
        ),
        const GpsPoint(
          lat: 48.852,
          lng: 2.352,
          itemId: 'b',
          storyId: 'story-a',
        ),
        const GpsPoint(lat: 48.853, lng: 2.353, itemId: 'c'),
      ]);
      expect(clusters.length, 1);
      expect(clusters.first.storyIds, <String>['story-a', 'story-z']);
    });
  });

  group('PlaceClusterer.fitPositions', () {
    test('a single cluster sits in the centre', () {
      final clusters = PlaceClusterer.cluster(<GpsPoint>[
        const GpsPoint(lat: 48.85, lng: 2.35, itemId: 'a'),
      ]);
      final positions = PlaceClusterer.fitPositions(clusters);
      expect(positions[clusters.first.id], (0.5, 0.5));
    });

    test('west is left, east is right, north is up', () {
      final clusters = PlaceClusterer.cluster(<GpsPoint>[
        const GpsPoint(lat: 51.50, lng: -0.12, itemId: 'london'),
        const GpsPoint(lat: 48.85, lng: 2.35, itemId: 'paris'),
      ]);
      final positions = PlaceClusterer.fitPositions(clusters);
      final londonId =
          clusters.firstWhere((c) => c.itemIds.contains('london')).id;
      final parisId =
          clusters.firstWhere((c) => c.itemIds.contains('paris')).id;
      final london = positions[londonId]!;
      final paris = positions[parisId]!;
      // London is west of Paris and north of it.
      expect(london.$1, lessThan(paris.$1));
      expect(london.$2, lessThan(paris.$2));
    });

    test('positions stay inside the padded map', () {
      final clusters = PlaceClusterer.cluster(<GpsPoint>[
        const GpsPoint(lat: -33.86, lng: 151.20, itemId: 'sydney'),
        const GpsPoint(lat: 51.50, lng: -0.12, itemId: 'london'),
        const GpsPoint(lat: 40.71, lng: -74.00, itemId: 'nyc'),
      ]);
      final positions = PlaceClusterer.fitPositions(clusters);
      for (final position in positions.values) {
        expect(position.$1, greaterThanOrEqualTo(0.12));
        expect(position.$1, lessThanOrEqualTo(0.88));
        expect(position.$2, greaterThanOrEqualTo(0.12));
        expect(position.$2, lessThanOrEqualTo(0.88));
      }
    });
  });

  group('PlaceClusterer.formatCoordinates', () {
    test('formats hemispheres and rounds to two decimals', () {
      expect(
        PlaceClusterer.formatCoordinates(48.8566, 2.3522),
        '48.86° N, 2.35° E',
      );
      expect(
        PlaceClusterer.formatCoordinates(-33.8688, -70.6693),
        '33.87° S, 70.67° W',
      );
    });
  });

  group('PlaceClusterer.distanceDegrees', () {
    test('the same point is zero apart', () {
      expect(
        PlaceClusterer.distanceDegrees(48.85, 2.35, 48.85, 2.35),
        0,
      );
    });

    test('one degree of latitude is about one degree apart', () {
      expect(
        PlaceClusterer.distanceDegrees(48.85, 2.35, 49.85, 2.35),
        closeTo(1.0, 0.001),
      );
    });
  });

  group('Place model', () {
    const place = Place(
      id: 'gps-4885-235',
      name: 'Paris',
      storyIds: <String>['cruise'],
      x: 0.5,
      y: 0.5,
      photoCount: 3,
      gpsLat: 48.85,
      gpsLng: 2.35,
      isDemo: false,
    );

    test('GPS survives a JSON round-trip', () {
      final rebuilt = Place.fromJson(place.toJson());
      expect(rebuilt.gpsLat, 48.85);
      expect(rebuilt.gpsLng, 2.35);
      expect(rebuilt.hasGps, isTrue);
      expect(rebuilt.name, 'Paris');
    });

    test('legacy JSON without GPS loads with nulls', () {
      final rebuilt = Place.fromJson(<String, Object?>{
        'id': 'place-old',
        'name': 'Old place',
        'storyIds': const <String>[],
        'x': 0.2,
        'y': 0.3,
        'photoCount': 1,
      });
      expect(rebuilt.gpsLat, isNull);
      expect(rebuilt.hasGps, isFalse);
    });

    test('copyWith renames without losing GPS', () {
      final renamed = place.copyWith(name: 'Paris, at last');
      expect(renamed.name, 'Paris, at last');
      expect(renamed.gpsLat, 48.85);
      expect(renamed.id, place.id);
    });
  });
}
