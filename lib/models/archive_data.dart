import 'account.dart';
import 'ask_result.dart';
import 'layer.dart';
import 'memory_item.dart';
import 'person.dart';
import 'place.dart';
import 'share_link.dart';
import 'story.dart';
import 'voice_note.dart';

/// Import queue status.
enum ImportStatus {
  /// Nothing queued.
  idle,

  /// Indexing is running.
  indexing,

  /// Indexing paused (e.g. waiting for the user to resume).
  paused,

  /// Everything indexed.
  done,
}

/// The import queue: everything lands here first, then gets indexed
/// into the archive. Progress is honest — indexed vs total, 0 bytes
/// uploaded.
class ImportState {
  /// Creates an import state.
  const ImportState({
    required this.total,
    required this.indexed,
    required this.status,
    this.sourceLabel = 'Camera roll',
  });

  /// Rebuilds an import state from stored JSON.
  factory ImportState.fromJson(Map<String, Object?> json) => ImportState(
        total: json['total'] as int,
        indexed: json['indexed'] as int,
        status: ImportStatus.values.byName(json['status'] as String),
        sourceLabel: json['sourceLabel'] as String? ?? 'Camera roll',
      );

  /// Total items waiting to be indexed.
  final int total;

  /// Items indexed so far.
  final int indexed;

  /// Queue status.
  final ImportStatus status;

  /// Where this batch came from.
  final String sourceLabel;

  /// Progress 0–1.
  double get progress => total <= 0 ? 1.0 : (indexed / total).clamp(0, 1).toDouble();

  /// Items still waiting.
  int get remaining => total - indexed;

  /// Serializes the import state for local storage.
  Map<String, Object?> toJson() => <String, Object?>{
        'total': total,
        'indexed': indexed,
        'status': status.name,
        'sourceLabel': sourceLabel,
      };

  /// Returns a copy with the given fields replaced.
  ImportState copyWith({
    int? total,
    int? indexed,
    ImportStatus? status,
    String? sourceLabel,
  }) =>
      ImportState(
        total: total ?? this.total,
        indexed: indexed ?? this.indexed,
        status: status ?? this.status,
        sourceLabel: sourceLabel ?? this.sourceLabel,
      );
}

/// The whole archive as one versioned document.
///
/// Persisted in Drift/SQLite (see [ArchiveStore]); v1 documents
/// stored as JSON in SharedPreferences are migrated on load.
class ArchiveData {
  /// Creates archive data.
  const ArchiveData({
    required this.version,
    required this.stories,
    required this.items,
    required this.layers,
    required this.people,
    required this.places,
    required this.voiceNotes,
    required this.shareLinks,
    required this.moments,
    required this.corrections,
    required this.account,
    required this.settings,
    required this.importState,
    required this.onboardingSeen,
  });

  /// An empty archive: what a first run starts from. Version 2 is the
  /// Drift-backed format; v1 documents are migrated on load.
  factory ArchiveData.empty() => ArchiveData(
        version: 2,
        stories: <Story>[],
        items: <MemoryItem>[],
        layers: <MemoryLayer>[],
        people: <Person>[],
        places: <Place>[],
        voiceNotes: <VoiceNote>[],
        shareLinks: <ShareLink>[],
        moments: <ReconstructedMoment>[],
        corrections: <String, List<String>>{},
        account: AccountState.guest(),
        settings: const ArchiveSettings(),
        importState: const ImportState(
          total: 0,
          indexed: 0,
          status: ImportStatus.idle,
        ),
        onboardingSeen: false,
      );

  /// Rebuilds archive data from stored JSON.
  factory ArchiveData.fromJson(Map<String, Object?> json) => ArchiveData(
        version: json['version'] as int? ?? 1,
        stories: (json['stories'] as List<dynamic>)
            .map((s) => Story.fromJson(s as Map<String, Object?>))
            .toList(),
        items: (json['items'] as List<dynamic>)
            .map((i) => MemoryItem.fromJson(i as Map<String, Object?>))
            .toList(),
        layers: (json['layers'] as List<dynamic>)
            .map((l) => MemoryLayer.fromJson(l as Map<String, Object?>))
            .toList(),
        people: (json['people'] as List<dynamic>)
            .map((p) => Person.fromJson(p as Map<String, Object?>))
            .toList(),
        places: (json['places'] as List<dynamic>)
            .map((p) => Place.fromJson(p as Map<String, Object?>))
            .toList(),
        voiceNotes: (json['voiceNotes'] as List<dynamic>)
            .map((v) => VoiceNote.fromJson(v as Map<String, Object?>))
            .toList(),
        shareLinks: (json['shareLinks'] as List<dynamic>)
            .map((s) => ShareLink.fromJson(s as Map<String, Object?>))
            .toList(),
        moments: (json['moments'] as List<dynamic>)
            .map((m) => ReconstructedMoment.fromJson(m as Map<String, Object?>))
            .toList(),
        corrections: (json['corrections'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, (v as List<dynamic>).cast<String>()),
        ),
        account:
            AccountState.fromJson(json['account'] as Map<String, Object?>),
        settings:
            ArchiveSettings.fromJson(json['settings'] as Map<String, Object?>),
        importState:
            ImportState.fromJson(json['importState'] as Map<String, Object?>),
        onboardingSeen: json['onboardingSeen'] as bool? ?? false,
      );

  /// Schema version of the stored document.
  final int version;

  /// Stories in the archive.
  final List<Story> stories;

  /// Memory items (the indexed library).
  final List<MemoryItem> items;

  /// Edit layers across all memories.
  final List<MemoryLayer> layers;

  /// People (face groups), named or unnamed.
  final List<Person> people;

  /// Places on the schematic map.
  final List<Place> places;

  /// Voice notes.
  final List<VoiceNote> voiceNotes;

  /// Active share links.
  final List<ShareLink> shareLinks;

  /// Reconstructed moments, newest first.
  final List<ReconstructedMoment> moments;

  /// What the user taught the archive: normalized question →
  /// item ids removed from that question's answer. The reconstructor
  /// excludes these items next time.
  final Map<String, List<String>> corrections;

  /// Account state.
  final AccountState account;

  /// Archive settings.
  final ArchiveSettings settings;

  /// Import queue state.
  final ImportState importState;

  /// True once the first-launch flow has been completed.
  final bool onboardingSeen;

  /// Serializes the archive for local storage.
  Map<String, Object?> toJson() => <String, Object?>{
        'version': version,
        'stories': stories.map((s) => s.toJson()).toList(),
        'items': items.map((i) => i.toJson()).toList(),
        'layers': layers.map((l) => l.toJson()).toList(),
        'people': people.map((p) => p.toJson()).toList(),
        'places': places.map((p) => p.toJson()).toList(),
        'voiceNotes': voiceNotes.map((v) => v.toJson()).toList(),
        'shareLinks': shareLinks.map((s) => s.toJson()).toList(),
        'moments': moments.map((m) => m.toJson()).toList(),
        'corrections': corrections,
        'account': account.toJson(),
        'settings': settings.toJson(),
        'importState': importState.toJson(),
        'onboardingSeen': onboardingSeen,
      };

  /// Returns a copy with the given fields replaced.
  ArchiveData copyWith({
    List<Story>? stories,
    List<MemoryItem>? items,
    List<MemoryLayer>? layers,
    List<Person>? people,
    List<Place>? places,
    List<VoiceNote>? voiceNotes,
    List<ShareLink>? shareLinks,
    List<ReconstructedMoment>? moments,
    Map<String, List<String>>? corrections,
    AccountState? account,
    ArchiveSettings? settings,
    ImportState? importState,
    bool? onboardingSeen,
  }) =>
      ArchiveData(
        version: version,
        stories: stories ?? this.stories,
        items: items ?? this.items,
        layers: layers ?? this.layers,
        people: people ?? this.people,
        places: places ?? this.places,
        voiceNotes: voiceNotes ?? this.voiceNotes,
        shareLinks: shareLinks ?? this.shareLinks,
        moments: moments ?? this.moments,
        corrections: corrections ?? this.corrections,
        account: account ?? this.account,
        settings: settings ?? this.settings,
        importState: importState ?? this.importState,
        onboardingSeen: onboardingSeen ?? this.onboardingSeen,
      );
}
