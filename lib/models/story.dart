/// A chapter inside a story: one remembered stretch, in the order the
/// user remembers it — chapters can be dragged to reorder.
class Chapter {
  /// Creates a chapter.
  const Chapter({
    required this.id,
    required this.storyId,
    required this.title,
    required this.caption,
    required this.day,
    required this.photoCount,
    required this.videoCount,
    required this.playSeconds,
    required this.order,
    this.coverFrameId,
  });

  /// Rebuilds a chapter from stored JSON.
  factory Chapter.fromJson(Map<String, Object?> json) => Chapter(
        id: json['id'] as String,
        storyId: json['storyId'] as String,
        title: json['title'] as String,
        caption: json['caption'] as String? ?? '',
        day: json['day'] as int,
        photoCount: json['photoCount'] as int,
        videoCount: json['videoCount'] as int,
        playSeconds: json['playSeconds'] as int,
        order: json['order'] as int,
        coverFrameId: json['coverFrameId'] as String?,
      );

  /// Stable id, e.g. `cruise-ch1`.
  final String id;

  /// The story this chapter belongs to.
  final String storyId;

  /// Chapter title, e.g. "Boarding, at dusk".
  final String title;

  /// The editable caption — the story in the user's own words.
  final String caption;

  /// Day number within the story (1-based).
  final int day;

  /// Photos in this chapter.
  final int photoCount;

  /// Videos in this chapter.
  final int videoCount;

  /// Play length of this chapter in seconds. The story total is the
  /// sum of its chapters.
  final int playSeconds;

  /// Position in the chapter order (0-based). Dragging to reorder
  /// rewrites these values.
  final int order;

  /// The cover frame of this chapter, by memory-item id.
  final String? coverFrameId;

  /// Serializes the chapter for local storage.
  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'storyId': storyId,
        'title': title,
        'caption': caption,
        'day': day,
        'photoCount': photoCount,
        'videoCount': videoCount,
        'playSeconds': playSeconds,
        'order': order,
        'coverFrameId': coverFrameId,
      };

  /// Returns a copy with the given fields replaced.
  Chapter copyWith({
    String? title,
    String? caption,
    int? day,
    int? photoCount,
    int? videoCount,
    int? playSeconds,
    int? order,
    String? coverFrameId,
  }) =>
      Chapter(
        id: id,
        storyId: storyId,
        title: title ?? this.title,
        caption: caption ?? this.caption,
        day: day ?? this.day,
        photoCount: photoCount ?? this.photoCount,
        videoCount: videoCount ?? this.videoCount,
        playSeconds: playSeconds ?? this.playSeconds,
        order: order ?? this.order,
        coverFrameId: coverFrameId ?? this.coverFrameId,
      );
}

/// A story: a curated collection of memories with chapters, e.g.
/// "Wedding Cruise" — Mediterranean Sea, 14 days, 2 people.
class Story {
  /// Creates a story.
  const Story({
    required this.id,
    required this.title,
    required this.place,
    required this.durationLabel,
    required this.days,
    required this.peopleCount,
    required this.chapters,
    required this.photoCount,
    required this.videoCount,
    required this.coverArt,
    required this.startedAt,
    this.isDemo = true,
  });

  /// Rebuilds a story from stored JSON.
  factory Story.fromJson(Map<String, Object?> json) => Story(
        id: json['id'] as String,
        title: json['title'] as String,
        place: json['place'] as String,
        durationLabel: json['durationLabel'] as String,
        days: json['days'] as int,
        peopleCount: json['peopleCount'] as int,
        chapters: (json['chapters'] as List<dynamic>)
            .map((c) => Chapter.fromJson(c as Map<String, Object?>))
            .toList(),
        photoCount: json['photoCount'] as int,
        videoCount: json['videoCount'] as int,
        coverArt: json['coverArt'] as String,
        startedAt: DateTime.parse(json['startedAt'] as String),
        isDemo: json['isDemo'] as bool? ?? true,
      );

  /// Stable id, e.g. `cruise`.
  final String id;

  /// Story title.
  final String title;

  /// Where the story happened, e.g. "Mediterranean Sea".
  final String place;

  /// Human duration, e.g. "14 days" or "35+ years".
  final String durationLabel;

  /// Length in days (0 for open-ended stories like Childhood).
  final int days;

  /// People in the story.
  final int peopleCount;

  /// Chapters in remembered order (sorted by [Chapter.order]).
  final List<Chapter> chapters;

  /// Photos in the story.
  final int photoCount;

  /// Videos in the story.
  final int videoCount;

  /// Gradient-art key for the story tile: `cruise`, `moto`, `family`,
  /// `childhood` or `moment` (for stories saved from a reconstruction).
  final String coverArt;

  /// When the story started — drives timeline placement.
  final DateTime startedAt;

  /// True for seeded demo-library content.
  final bool isDemo;

  /// Total play time: the sum of the chapters' play times.
  int get playSeconds =>
      chapters.fold(0, (sum, chapter) => sum + chapter.playSeconds);

  /// Chapters in remembered order.
  List<Chapter> get orderedChapters {
    final sorted = List<Chapter>.of(chapters);
    sorted.sort((a, b) => a.order.compareTo(b.order));
    return sorted;
  }

  /// Serializes the story for local storage.
  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'title': title,
        'place': place,
        'durationLabel': durationLabel,
        'days': days,
        'peopleCount': peopleCount,
        'chapters': chapters.map((c) => c.toJson()).toList(),
        'photoCount': photoCount,
        'videoCount': videoCount,
        'coverArt': coverArt,
        'startedAt': startedAt.toIso8601String(),
        'isDemo': isDemo,
      };

  /// Returns a copy with the given fields replaced.
  Story copyWith({
    String? title,
    List<Chapter>? chapters,
    int? photoCount,
    int? videoCount,
  }) =>
      Story(
        id: id,
        title: title ?? this.title,
        place: place,
        durationLabel: durationLabel,
        days: days,
        peopleCount: peopleCount,
        chapters: chapters ?? this.chapters,
        photoCount: photoCount ?? this.photoCount,
        videoCount: videoCount ?? this.videoCount,
        coverArt: coverArt,
        startedAt: startedAt,
        isDemo: isDemo,
      );
}
