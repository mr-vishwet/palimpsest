/// A place in the archive.
///
/// The map is schematic on purpose: places, not streets. Each place
/// carries a position on the schematic map as fractions (0–1) of the
/// map area, plus the stories pinned to it.
class Place {
  /// Creates a place.
  const Place({
    required this.id,
    required this.name,
    required this.storyIds,
    required this.x,
    required this.y,
    required this.photoCount,
    this.isDemo = true,
  });

  /// Rebuilds a place from stored JSON.
  factory Place.fromJson(Map<String, Object?> json) => Place(
        id: json['id'] as String,
        name: json['name'] as String,
        storyIds: (json['storyIds'] as List<dynamic>).cast<String>(),
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        photoCount: json['photoCount'] as int,
        isDemo: json['isDemo'] as bool? ?? true,
      );

  /// Stable id, e.g. `place-mediterranean`.
  final String id;

  /// Place name, e.g. "Mediterranean Sea".
  final String name;

  /// Stories pinned to this place.
  final List<String> storyIds;

  /// Horizontal position on the schematic map (0–1).
  final double x;

  /// Vertical position on the schematic map (0–1).
  final double y;

  /// Photos taken at this place.
  final int photoCount;

  /// True for seeded demo-library content.
  final bool isDemo;

  /// Serializes the place for local storage.
  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'name': name,
        'storyIds': storyIds,
        'x': x,
        'y': y,
        'photoCount': photoCount,
        'isDemo': isDemo,
      };
}
