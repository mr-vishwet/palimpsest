import '../models/memory_item.dart';
import '../models/person.dart';
import '../models/place.dart';
import '../models/story.dart';
import '../models/voice_note.dart';

/// One search result: the item, its score, and why it matched.
///
/// The reason is user-facing — the archive shows its working, so every
/// result can explain itself.
class SearchHit {
  /// Creates a search hit.
  const SearchHit({
    required this.item,
    required this.score,
    required this.reason,
  });

  /// The matching memory.
  final MemoryItem item;

  /// Match strength. Hits below [ArchiveIndex.weakThreshold] are
  /// flagged as possibly wrong by the reconstructor.
  final double score;

  /// Why this item matched, in plain words.
  final String reason;
}

/// The on-device search index.
///
/// Keyword/date/tag search over the local library — no account, no
/// upload, no server. Scoring is deterministic: the same query over
/// the same library always returns the same order. AI features
/// (embeddings, transcription) are deferred adapters in the catalog;
/// v0.1 searches titles, tags, captions, people, places and voice-note
/// transcripts.
class ArchiveIndex {
  /// Builds an index over the given library.
  ArchiveIndex({
    required List<MemoryItem> items,
    required List<VoiceNote> voiceNotes,
    required List<Person> people,
    required List<Place> places,
    required List<Story> stories,
  })  : _items = items,
        _voiceNotes = voiceNotes,
        _people = {for (final p in people) p.id: p},
        _places = {for (final p in places) p.id: p},
        _stories = {for (final s in stories) s.id: s};

  /// Hits at or below this score are weak matches.
  static const double weakThreshold = 3;

  final List<MemoryItem> _items;
  final List<VoiceNote> _voiceNotes;
  final Map<String, Person> _people;
  final Map<String, Place> _places;
  final Map<String, Story> _stories;

  /// Words that carry no search meaning.
  static const Set<String> _stopwords = <String>{
    'a', 'an', 'the', 'me', 'my', 'show', 'find', 'get', 'when', 'where',
    'what', 'which', 'that', 'this', 'with', 'from', 'and', 'or', 'of',
    'in', 'on', 'at', 'it', 'is', 'was', 'were', 'i', 'started', 'first',
  };

  /// Splits a query into meaningful lowercase tokens.
  static List<String> tokenize(String query) => query
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((token) => token.length > 1 && !_stopwords.contains(token))
      .toList(growable: false);

  /// Normalizes a query for correction lookup.
  static String normalize(String query) => tokenize(query).join(' ');

  /// Searches the library for [query], optionally narrowed by filters.
  ///
  /// Results are sorted by score (highest first), then by capture time
  /// (newest first) so ties are stable and deterministic.
  List<SearchHit> search(
    String query, {
    String? storyId,
    MediaKind? kind,
    String? personId,
    String? placeId,
    String? aspectRatio,
    DateTime? from,
    DateTime? to,
  }) {
    final tokens = tokenize(query);
    final hits = <SearchHit>[];
    for (final item in _items) {
      if (storyId != null && item.storyId != storyId) {
        continue;
      }
      if (kind != null && item.kind != kind) {
        continue;
      }
      if (personId != null && !item.personIds.contains(personId)) {
        continue;
      }
      if (placeId != null && item.placeId != placeId) {
        continue;
      }
      if (aspectRatio != null && item.aspectRatio != aspectRatio) {
        continue;
      }
      if (from != null && item.takenAt.isBefore(from)) {
        continue;
      }
      if (to != null && item.takenAt.isAfter(to)) {
        continue;
      }
      if (tokens.isEmpty) {
        hits.add(
          SearchHit(item: item, score: 1, reason: 'In the library'),
        );
        continue;
      }
      final scored = _score(item, tokens);
      if (scored != null) {
        hits.add(scored);
      }
    }
    hits.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) {
        return byScore;
      }
      return b.item.takenAt.compareTo(a.item.takenAt);
    });
    return hits;
  }

  /// Searches voice-note transcripts for [query].
  List<VoiceNote> searchVoiceNotes(String query) {
    final tokens = tokenize(query);
    if (tokens.isEmpty) {
      return List<VoiceNote>.of(_voiceNotes);
    }
    return _voiceNotes.where((note) {
      final haystack = '${note.title} ${note.transcript}'.toLowerCase();
      return tokens.any(haystack.contains);
    }).toList(growable: false);
  }

  /// Scores one item against the query tokens, or null when it does
  /// not match at all.
  SearchHit? _score(MemoryItem item, List<String> tokens) {
    var score = 0.0;
    String? bestReason;
    var bestWeight = 0.0;

    void consider(double weight, String reason) {
      score += weight;
      if (weight > bestWeight) {
        bestWeight = weight;
        bestReason = reason;
      }
    }

    final title = item.title.toLowerCase();
    final note = (item.note ?? '').toLowerCase();
    final tags = item.tags.map((t) => t.toLowerCase()).toList(growable: false);
    final storyTitle = _stories[item.storyId]?.title.toLowerCase() ?? '';
    final placeName = _places[item.placeId]?.name.toLowerCase() ?? '';
    final peopleNames = item.personIds
        .map((id) => _people[id]?.name?.toLowerCase() ?? '')
        .where((name) => name.isNotEmpty)
        .toList(growable: false);
    final transcript = item.kind == MediaKind.voiceNote
        ? _voiceNotes
            .where((v) => v.id == item.id)
            .map((v) => v.transcript.toLowerCase())
            .join(' ')
        : '';

    for (final token in tokens) {
      if (tags.contains(token)) {
        consider(4, "Tagged '$token'");
      } else if (tags.any((tag) => tag.contains(token))) {
        consider(2, "Tagged ${item.tags.firstWhere((tag) => tag.toLowerCase().contains(token))}");
      }
      if (title.contains(token)) {
        consider(3, "Called '${item.title}'");
      }
      if (note.contains(token)) {
        consider(2, 'Mentioned in the caption');
      }
      if (peopleNames.any((name) => name.contains(token))) {
        consider(3, '${_people[item.personIds.firstWhere((id) => (_people[id]?.name ?? '').toLowerCase().contains(token))]?.displayName ?? 'Someone'} is in this ${item.kind.name}');
      }
      if (placeName.contains(token)) {
        consider(2, 'Taken at ${_places[item.placeId]?.name ?? 'this place'}');
      }
      if (storyTitle.contains(token)) {
        consider(1, 'Part of ${_stories[item.storyId]?.title ?? 'a story'}');
      }
      if (transcript.contains(token)) {
        consider(2, 'Said in the voice note');
      }
      if (token == 'weekend' &&
          (item.takenAt.weekday == DateTime.saturday ||
              item.takenAt.weekday == DateTime.sunday)) {
        consider(1, 'Taken on a weekend');
      }
      if (token == 'rain' && tags.contains('rain')) {
        consider(1, 'It rained that day');
      }
    }

    if (score <= 0) {
      return null;
    }
    return SearchHit(
      item: item,
      score: score,
      reason: bestReason ?? 'Matched the question',
    );
  }
}
