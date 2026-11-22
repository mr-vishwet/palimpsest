/// A person in the archive, grouped on-device by face.
///
/// Names are the user's to add: a group starts unnamed ("Unnamed group")
/// and becomes a person when the user names it. Grouping runs only
/// on-device, and only while charging (see Settings).
class Person {
  /// Creates a person.
  const Person({
    required this.id,
    required this.photoCount,
    required this.colorKey,
    this.name,
    this.isDemo = false,
  });

  /// Rebuilds a person from stored JSON.
  factory Person.fromJson(Map<String, Object?> json) => Person(
        id: json['id'] as String,
        photoCount: json['photoCount'] as int,
        colorKey: json['colorKey'] as String,
        name: json['name'] as String?,
        isDemo: json['isDemo'] as bool? ?? false,
      );

  /// Stable id, e.g. `person-dad`.
  final String id;

  /// Photos this person appears in.
  final int photoCount;

  /// Avatar tint key: `gold`, `cyan`, `pink`, `green` or `blue`.
  final String colorKey;

  /// The name the user gave this group, or null when unnamed.
  final String? name;

  /// True for demo-media content (loaded from the bundled demo set).
  /// Real imports and user-created content are false.
  final bool isDemo;

  /// True when the user has named this group.
  bool get isNamed => name != null && name!.isNotEmpty;

  /// Display name: the given name, or "Unnamed group".
  String get displayName => isNamed ? name! : 'Unnamed group';

  /// Serializes the person for local storage.
  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'photoCount': photoCount,
        'colorKey': colorKey,
        'name': name,
        'isDemo': isDemo,
      };

  /// Returns a copy with the given fields replaced.
  Person copyWith({String? name, int? photoCount}) => Person(
        id: id,
        photoCount: photoCount ?? this.photoCount,
        colorKey: colorKey,
        name: name ?? this.name,
        isDemo: isDemo,
      );
}
