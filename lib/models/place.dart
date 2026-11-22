/// A place in the archive.
///
/// The map is schematic on purpose: places, not streets. Each place
/// carries a position on the schematic map as fractions (0–1) of the
/// map area, plus the stories pinned to it.
///
/// Places now come from two sources: the old hand-placed demo places,
/// and real GPS clusters derived from imported photos (see
/// `PlaceClusterer`). A GPS place carries its coordinates in
/// [gpsLat]/[gpsLng]; its schematic [x]/[y] are fitted from the
/// cluster bounds so the map stays readable. A place the user names
/// keeps the cluster's id, so re-imports merge instead of duplicating.
class Place {
  /// Creates a place.
  const Place({
    required this.id,
    required this.name,
    required this.storyIds,
    required this.x,
    required this.y,
    required this.photoCount,
    this.gpsLat,
    this.gpsLng,
    this.isDemo = false,
  });

  /// Rebuilds a place from stored JSON.
  factory Place.fromJson(Map<String, Object?> json) => Place(
        id: json['id'] as String,
        name: json['name'] as String,
        storyIds: (json['storyIds'] as List<dynamic>).cast<String>(),
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        photoCount: json['photoCount'] as int,
        gpsLat: (json['gpsLat'] as num?)?.toDouble(),
        gpsLng: (json['gpsLng'] as num?)?.toDouble(),
        isDemo: json['isDemo'] as bool? ?? false,
      );

  /// Stable id, e.g. `place-mediterranean`. GPS places use the
  /// cluster id (`gps-…`), so a named place survives re-imports.
  final String id;

  /// Place name, e.g. "Mediterranean Sea". Unnamed GPS clusters show
  /// as "Unnamed place" until the user names them.
  final String name;

  /// Stories pinned to this place.
  final List<String> storyIds;

  /// Horizontal position on the schematic map (0–1).
  final double x;

  /// Vertical position on the schematic map (0–1).
  final double y;

  /// Photos taken at this place.
  final int photoCount;

  /// GPS latitude in degrees, from EXIF. Null for hand-placed places.
  final double? gpsLat;

  /// GPS longitude in degrees, from EXIF. Null for hand-placed places.
  final double? gpsLng;

  /// True for demo-media content (loaded from the bundled demo set).
  /// Real imports and user-created content are false.
  final bool isDemo;

  /// True when this place comes from real GPS coordinates.
  bool get hasGps => gpsLat != null && gpsLng != null;

  /// Serializes the place for local storage.
  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'name': name,
        'storyIds': storyIds,
        'x': x,
        'y': y,
        'photoCount': photoCount,
        'gpsLat': gpsLat,
        'gpsLng': gpsLng,
        'isDemo': isDemo,
      };

  /// Returns a copy with the given fields replaced.
  Place copyWith({
    String? name,
    List<String>? storyIds,
    double? x,
    double? y,
    int? photoCount,
    double? gpsLat,
    double? gpsLng,
    bool? isDemo,
  }) =>
      Place(
        id: id,
        name: name ?? this.name,
        storyIds: storyIds ?? this.storyIds,
        x: x ?? this.x,
        y: y ?? this.y,
        photoCount: photoCount ?? this.photoCount,
        gpsLat: gpsLat ?? this.gpsLat,
        gpsLng: gpsLng ?? this.gpsLng,
        isDemo: isDemo ?? this.isDemo,
      );
}
