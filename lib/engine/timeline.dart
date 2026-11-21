import '../models/memory_item.dart';
import '../models/story.dart';

/// One year of the timeline: the year's memories and the stories that
/// started in it.
class TimelineYear {
  /// Creates a timeline year.
  const TimelineYear({
    required this.year,
    required this.items,
    required this.stories,
  });

  /// The calendar year.
  final int year;

  /// Memories from this year, newest first.
  final List<MemoryItem> items;

  /// Stories that started this year, newest first.
  final List<Story> stories;
}

/// Builds the timeline: years newest first, memories newest first
/// within each year, stories placed by their start date.
///
/// Pure and deterministic — the same library always builds the same
/// timeline.
abstract final class TimelineBuilder {
  /// Groups [items] and [stories] into years, newest year first.
  static List<TimelineYear> build(
    List<MemoryItem> items,
    List<Story> stories,
  ) {
    final byYear = <int, List<MemoryItem>>{};
    for (final item in items) {
      byYear.putIfAbsent(item.takenAt.year, () => <MemoryItem>[]).add(item);
    }
    final storiesByYear = <int, List<Story>>{};
    for (final story in stories) {
      storiesByYear
          .putIfAbsent(story.startedAt.year, () => <Story>[])
          .add(story);
    }

    final years = <int>{...byYear.keys, ...storiesByYear.keys}.toList()
      ..sort((a, b) => b.compareTo(a));

    return years.map((year) {
      final yearItems = List<MemoryItem>.of(byYear[year] ?? const <MemoryItem>[])
        ..sort((a, b) => b.takenAt.compareTo(a.takenAt));
      final yearStories = List<Story>.of(storiesByYear[year] ?? const <Story>[])
        ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
      return TimelineYear(year: year, items: yearItems, stories: yearStories);
    }).toList(growable: false);
  }

  /// All items newest first.
  static List<MemoryItem> newestFirst(List<MemoryItem> items) {
    final sorted = List<MemoryItem>.of(items);
    sorted.sort((a, b) => b.takenAt.compareTo(a.takenAt));
    return sorted;
  }

  /// All items oldest first (chronological — the order a story plays).
  static List<MemoryItem> oldestFirst(List<MemoryItem> items) {
    final sorted = List<MemoryItem>.of(items);
    sorted.sort((a, b) => a.takenAt.compareTo(b.takenAt));
    return sorted;
  }
}
