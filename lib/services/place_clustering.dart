/// Real places from GPS: imported photos and videos carry EXIF
/// coordinates, and nearby coordinates cluster into one place.
///
/// Clustering is a simple fixed grid — deterministic, no network, no
/// API key. A cluster becomes a [Place] only when the user names it;
/// until then the places screen shows it as an unnamed place with its
/// coordinates. Reverse-geocoding (GPS → street name) is deliberately
/// not part of this pass: it would send the user's locations to a
/// third party and break the local-first story.
library;

import 'dart:math' as math;

/// One GPS reading attached to a memory item.
class GpsPoint {
  /// Creates a GPS point.
  const GpsPoint({
    required this.lat,
    required this.lng,
    required this.itemId,
    this.storyId,
    this.takenAt,
  });

  /// Latitude in degrees.
  final double lat;

  /// Longitude in degrees.
  final double lng;

  /// The memory item this reading came from.
  final String itemId;

  /// The story the item belongs to, if any.
  final String? storyId;

  /// When the item was taken, if known.
  final DateTime? takenAt;
}

/// A cluster of nearby GPS points — one real place on the map.
class GpsCluster {
  /// Creates a cluster.
  const GpsCluster({
    required this.id,
    required this.points,
    required this.centerLat,
    required this.centerLng,
  });

  /// Deterministic id from the grid cell, e.g. `gps-4885-235`.
  final String id;

  /// The points in this cluster, in input order.
  final List<GpsPoint> points;

  /// Mean latitude of the points.
  final double centerLat;

  /// Mean longitude of the points.
  final double centerLng;

  /// How many memories were taken here.
  int get count => points.length;

  /// Ids of the memories in this cluster.
  List<String> get itemIds =>
      points.map((p) => p.itemId).toList(growable: false);

  /// Stories represented here, sorted.
  List<String> get storyIds {
    final ids = <String>{
      for (final p in points)
        if (p.storyId != null) p.storyId!,
    }.toList(growable: false)
      ..sort();
    return ids;
  }
}

/// Grid clustering of GPS points into places, plus the helpers the
/// places screen needs to show them.
abstract final class PlaceClusterer {
  /// Grid cell size in degrees. 0.01° is about 1.1 km at the equator —
  /// a neighbourhood, not a street corner.
  static const double defaultCellDegrees = 0.01;

  /// Padding (fraction of the map) around the fitted bounds, so pins
  /// never sit on the map's edge.
  static const double fitPadding = 0.12;

  /// Groups [points] into clusters by grid cell.
  ///
  /// Deterministic: the same points always produce the same clusters
  /// in the same order (sorted by cluster id). Points with invalid
  /// coordinates (NaN, or outside ±90/±180) are ignored.
  static List<GpsCluster> cluster(
    List<GpsPoint> points, {
    double cellDegrees = defaultCellDegrees,
  }) {
    final cells = <String, List<GpsPoint>>{};
    for (final point in points) {
      if (!_isValid(point.lat, point.lng)) {
        continue;
      }
      final cellLat = (point.lat / cellDegrees).floor();
      final cellLng = (point.lng / cellDegrees).floor();
      final key = '$cellLat:$cellLng';
      (cells[key] ??= <GpsPoint>[]).add(point);
    }
    final clusters = <GpsCluster>[];
    for (final entry in cells.entries) {
      final pts = entry.value;
      var latSum = 0.0;
      var lngSum = 0.0;
      for (final p in pts) {
        latSum += p.lat;
        lngSum += p.lng;
      }
      clusters.add(
        GpsCluster(
          id: 'gps-${entry.key.replaceAll(':', '-').replaceAll('.', 'p')}',
          points: List<GpsPoint>.unmodifiable(pts),
          centerLat: latSum / pts.length,
          centerLng: lngSum / pts.length,
        ),
      );
    }
    clusters.sort((a, b) => a.id.compareTo(b.id));
    return clusters;
  }

  /// Fits every cluster centre into schematic 0–1 map coordinates,
  /// spreading them across the map with [fitPadding] around the edges.
  ///
  /// Longitude maps west → 0, east → 1; latitude maps north → 0,
  /// south → 1 (map y grows downward). A single cluster, or clusters
  /// sharing one coordinate, sit at the centre of that axis. Returns
  /// a map from cluster id to (x, y).
  static Map<String, (double, double)> fitPositions(
    List<GpsCluster> clusters,
  ) {
    final positions = <String, (double, double)>{};
    if (clusters.isEmpty) {
      return positions;
    }
    var minLat = double.infinity;
    var maxLat = double.negativeInfinity;
    var minLng = double.infinity;
    var maxLng = double.negativeInfinity;
    for (final c in clusters) {
      minLat = math.min(minLat, c.centerLat);
      maxLat = math.max(maxLat, c.centerLat);
      minLng = math.min(minLng, c.centerLng);
      maxLng = math.max(maxLng, c.centerLng);
    }
    final latSpan = maxLat - minLat;
    final lngSpan = maxLng - minLng;
    const usable = 1 - 2 * fitPadding;
    for (final c in clusters) {
      final x = lngSpan <= 0
          ? 0.5
          : fitPadding + ((c.centerLng - minLng) / lngSpan) * usable;
      final y = latSpan <= 0
          ? 0.5
          : fitPadding + ((maxLat - c.centerLat) / latSpan) * usable;
      positions[c.id] = (x, y);
    }
    return positions;
  }

  /// Formats coordinates for display, e.g. `48.85° N, 2.35° E`.
  static String formatCoordinates(double lat, double lng) {
    final latHemisphere = lat < 0 ? 'S' : 'N';
    final lngHemisphere = lng < 0 ? 'W' : 'E';
    return '${lat.abs().toStringAsFixed(2)}° $latHemisphere, '
        '${lng.abs().toStringAsFixed(2)}° $lngHemisphere';
  }

  /// Great-circle-ish distance in degrees between two coordinates
  /// (equirectangular approximation — good enough for "is this the
  /// same place" checks at neighbourhood scale).
  static double distanceDegrees(
    double latA,
    double lngA,
    double latB,
    double lngB,
  ) {
    final dLat = latA - latB;
    final meanLat = (latA + latB) / 2 * math.pi / 180;
    final dLng = (lngA - lngB) * math.cos(meanLat);
    return math.sqrt(dLat * dLat + dLng * dLng);
  }

  static bool _isValid(double lat, double lng) =>
      !lat.isNaN &&
      !lng.isNaN &&
      lat >= -90 &&
      lat <= 90 &&
      lng >= -180 &&
      lng <= 180;
}
