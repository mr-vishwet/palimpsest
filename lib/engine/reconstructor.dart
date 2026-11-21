import '../models/archive_data.dart';
import '../models/ask_result.dart';
import '../models/memory_item.dart';
import 'archive_index.dart';

/// One anchor find shown while a moment reconstructs: the first sketch,
/// the first voice note, the first cut — the evidence the answer is
/// built from.
class AnchorFind {
  /// Creates an anchor find.
  const AnchorFind({required this.label, required this.itemId});

  /// Human label, e.g. "First sketch — Saturday 09:12".
  final String label;

  /// The item id it points at.
  final String itemId;
}

/// Rebuilds a moment from a question.
///
/// The breakpoint flow: ask → reconstructing → reconstructed moment.
/// The reconstruction is a real search over the local index: items are
/// scored, ordered chronologically, and each carries the reason it is
/// there. Weak matches are flagged as possibly wrong, and items the
/// user previously removed for the same question are excluded — the
/// correction is remembered.
abstract final class Reconstructor {
  /// The tag marking the canonical project-weekend items in the demo
  /// library.
  static const String projectWeekendTag = 'project-weekend';

  /// Reconstructs a moment for [query] over [data].
  static ReconstructedMoment reconstruct(
    String query,
    ArchiveData data, {
    DateTime? now,
  }) {
    final stopwatch = Stopwatch()..start();
    final momentNow = now ?? DateTime.now();
    final index = ArchiveIndex(
      items: data.items,
      voiceNotes: data.voiceNotes,
      people: data.people,
      places: data.places,
      stories: data.stories,
    );

    final normalized = ArchiveIndex.normalize(query);
    final correctedAway =
        data.corrections[normalized] ?? const <String>[];

    List<SearchHit> hits;
    if (_isCanonical(query)) {
      // The hero question: the weekend the project started. The demo
      // library tags those items explicitly, so the answer is exact —
      // and two weakly-tagged items are flagged as looking wrong.
      hits = data.items
          .where((item) => item.tags.contains(projectWeekendTag))
          .map(
            (item) => SearchHit(
              item: item,
              score: _canonicalScore(item),
              reason: _canonicalReason(item),
            ),
          )
          .toList(growable: false);
    } else {
      hits = index.search(query);
    }

    hits = hits
        .where((hit) => !correctedAway.contains(hit.item.id))
        .toList(growable: false);
    hits.sort((a, b) => a.item.takenAt.compareTo(b.item.takenAt));

    final flagged = hits
        .where((hit) => hit.score <= ArchiveIndex.weakThreshold)
        .map((hit) => hit.item.id)
        .toList(growable: false);

    stopwatch.stop();
    return ReconstructedMoment(
      id: 'moment-${momentNow.millisecondsSinceEpoch}',
      query: query,
      title: titleFor(query),
      createdAt: momentNow,
      itemIds: hits.map((hit) => hit.item.id).toList(growable: false),
      reasons: {
        for (final hit in hits) hit.item.id: hit.reason,
      },
      flaggedIds: flagged,
      rebuildMs: stopwatch.elapsedMilliseconds,
    );
  }

  /// The anchor finds for a moment: the earliest photo, the earliest
  /// voice note and the earliest video — the three finds the
  /// reconstructing screen shows as it works.
  static List<AnchorFind> anchorFinds(
    ReconstructedMoment moment,
    List<MemoryItem> items,
  ) {
    final byId = {for (final item in items) item.id: item};
    final ordered = moment.itemIds
        .map((id) => byId[id])
        .whereType<MemoryItem>()
        .toList(growable: false);
    final anchors = <AnchorFind>[];

    // The earliest item of a kind — unless a named milestone exists
    // ("First cut"), which is the anchor even when it is not the
    // earliest of its kind.
    MemoryItem? firstOf(MediaKind kind, {String? titled}) {
      MemoryItem? earliest;
      for (final item in ordered) {
        if (item.kind != kind) {
          continue;
        }
        earliest ??= item;
        if (titled != null && item.title == titled) {
          return item;
        }
      }
      return earliest;
    }

    void addAnchor(MemoryItem? item) {
      if (item == null) {
        return;
      }
      anchors.add(
        AnchorFind(
          label: '${item.title} — ${_shortDay(item.takenAt)}',
          itemId: item.id,
        ),
      );
    }

    addAnchor(firstOf(MediaKind.photo));
    addAnchor(firstOf(MediaKind.voiceNote));
    addAnchor(firstOf(MediaKind.video, titled: 'First cut'));
    return anchors;
  }

  /// A title for the question. The canonical question gets its
  /// canonical title; anything else is tidied into a moment title.
  static String titleFor(String query) {
    final trimmed = query.trim();
    if (_isCanonical(trimmed)) {
      return 'The weekend the project started';
    }
    var title = trimmed;
    for (final prefix in <String>[
      'show me ',
      'find ',
      'every ',
    ]) {
      if (title.toLowerCase().startsWith(prefix)) {
        title = title.substring(prefix.length);
        break;
      }
    }
    if (title.isEmpty) {
      return 'A moment';
    }
    return title[0].toUpperCase() + title.substring(1);
  }

  /// True when the question is the canonical hero question (or the
  /// short suggested-question form of it).
  static bool _isCanonical(String query) {
    final lower = query.toLowerCase();
    if (lower.contains('weekend') && lower.contains('project')) {
      return true;
    }
    return lower.trim() == 'the weekend the project started';
  }

  /// Canonical scoring: items from the project weekend score high;
  /// the two weakly-tagged strays score at the weak threshold so the
  /// UI flags them as looking wrong.
  static double _canonicalScore(MemoryItem item) {
    if (item.tags.contains('looks-wrong')) {
      return ArchiveIndex.weakThreshold;
    }
    if (item.title.startsWith('First ')) {
      return 9;
    }
    return 6;
  }

  /// Canonical reasons: the first sketch, the first voice note and the
  /// first cut carry their story; the rest carry their tag.
  static String _canonicalReason(MemoryItem item) {
    if (item.title == 'First sketch') {
      return 'First sketch — Saturday 09:12';
    }
    if (item.title == 'First voice note') {
      return 'First voice note — Saturday 22:40';
    }
    if (item.title == 'First cut') {
      return 'First cut — Sunday 18:03';
    }
    if (item.tags.contains('looks-wrong')) {
      return 'Matched "project" — from a different weekend';
    }
    return 'From the project weekend';
  }

  static String _shortDay(DateTime at) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final hh = at.hour.toString().padLeft(2, '0');
    final mm = at.minute.toString().padLeft(2, '0');
    return '${weekdays[at.weekday - 1]} $hh:$mm';
  }
}
