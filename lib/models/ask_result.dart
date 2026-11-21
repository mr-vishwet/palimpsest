/// A reconstructed moment: the answer to one question.
///
/// The archive answers with the collection — in order, with the reason
/// each item is there. Items the archive is unsure about are flagged
/// ("looks wrong"); removing one teaches the archive what was meant,
/// and the correction is remembered for the next time the same
/// question is asked.
class ReconstructedMoment {
  /// Creates a reconstructed moment.
  const ReconstructedMoment({
    required this.id,
    required this.query,
    required this.title,
    required this.createdAt,
    required this.itemIds,
    required this.reasons,
    required this.flaggedIds,
    required this.rebuildMs,
    this.removedIds = const <String>[],
    this.savedAsStoryId,
  });

  /// Rebuilds a moment from stored JSON.
  factory ReconstructedMoment.fromJson(Map<String, Object?> json) =>
      ReconstructedMoment(
        id: json['id'] as String,
        query: json['query'] as String,
        title: json['title'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        itemIds: (json['itemIds'] as List<dynamic>).cast<String>(),
        reasons: (json['reasons'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, v as String)),
        flaggedIds: (json['flaggedIds'] as List<dynamic>).cast<String>(),
        rebuildMs: json['rebuildMs'] as int,
        removedIds: (json['removedIds'] as List<dynamic>?)?.cast<String>() ??
            const <String>[],
        savedAsStoryId: json['savedAsStoryId'] as String?,
      );

  /// Stable id, e.g. `moment-project-weekend`.
  final String id;

  /// The question that was asked.
  final String query;

  /// The moment's title, e.g. "The weekend the project started".
  final String title;

  /// When the moment was reconstructed.
  final DateTime createdAt;

  /// Item ids in display order (chronological).
  final List<String> itemIds;

  /// Why each item is here, keyed by item id.
  final Map<String, String> reasons;

  /// Item ids the archive flagged as possibly wrong.
  final List<String> flaggedIds;

  /// How long the on-device rebuild took, in milliseconds.
  final int rebuildMs;

  /// Item ids the user removed from this moment.
  final List<String> removedIds;

  /// Story id when the moment was saved as a story.
  final String? savedAsStoryId;

  /// Items still in the moment (flagged items stay until removed).
  List<String> get visibleItemIds =>
      itemIds.where((id) => !removedIds.contains(id)).toList(growable: false);

  /// Reason for an item, or a generic fallback.
  String reasonFor(String itemId) =>
      reasons[itemId] ?? 'Matched the question';

  /// Serializes the moment for local storage.
  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'query': query,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'itemIds': itemIds,
        'reasons': reasons,
        'flaggedIds': flaggedIds,
        'rebuildMs': rebuildMs,
        'removedIds': removedIds,
        'savedAsStoryId': savedAsStoryId,
      };

  /// Returns a copy with the given fields replaced.
  ReconstructedMoment copyWith({
    List<String>? removedIds,
    String? savedAsStoryId,
  }) =>
      ReconstructedMoment(
        id: id,
        query: query,
        title: title,
        createdAt: createdAt,
        itemIds: itemIds,
        reasons: reasons,
        flaggedIds: flaggedIds,
        rebuildMs: rebuildMs,
        removedIds: removedIds ?? this.removedIds,
        savedAsStoryId: savedAsStoryId ?? this.savedAsStoryId,
      );
}
