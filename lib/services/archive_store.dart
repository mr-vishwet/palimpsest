import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/account.dart';
import '../models/archive_data.dart';
import '../models/ask_result.dart';
import '../models/layer.dart';
import '../models/memory_item.dart';
import '../models/person.dart';
import '../models/place.dart';
import '../models/share_link.dart';
import '../models/story.dart';
import '../models/voice_note.dart';
import 'app_database.dart';

/// Thrown when stored data exists but cannot be read — the database
/// is unreachable, or a v1 document is present but unparseable. The
/// caller shows a recovery screen instead of treating this as a
/// first run.
class ArchiveLoadException implements Exception {
  /// Creates a load failure carrying a user-facing [message].
  const ArchiveLoadException(this.message);

  /// What went wrong, in words the recovery screen can show.
  final String message;

  @override
  String toString() => 'ArchiveLoadException: $message';
}

/// Local-first persistence for the whole archive.
///
/// The archive lives in Drift/SQLite: one table per top-level
/// collection, each row carrying the full entity JSON plus the
/// columns the archive queries on. The interface stays narrow
/// (`load` / `save` / `clear`) so callers never see the store.
///
/// Save strategy (v1, documented choice): each `save()` runs one
/// transaction that upserts every entity and deletes rows whose ids
/// are no longer in the document. No diffing, no partial writes —
/// the document is small (hundreds of rows) and a full upsert pass
/// is simpler to reason about than a diff. If archives grow large
/// enough for this to matter, the per-entity upsert below is the
/// seam to make incremental.
///
/// Migration: v0.1 stored the archive as one JSON document in
/// SharedPreferences under [storageKey]. The first load after the
/// upgrade migrates that document into Drift — dropping seeded demo
/// content (seed data never survives the upgrade) — and removes the
/// old key.
///
/// `load()` returns null ONLY when genuinely nothing is stored. A
/// stored archive that cannot be read — the database unreachable,
/// or a v1 document present but unparseable — throws
/// [ArchiveLoadException] instead: reporting "no archive" on a
/// failed read would let the caller persist an empty archive over
/// the user's data (save prunes rows that are no longer in the
/// document). The caller shows a recovery screen (retry / start
/// fresh) and never overwrites on a failed read.
class ArchiveStore {
  /// Creates the store over the platform database, or over [database]
  /// when tests pass an in-memory one.
  ArchiveStore({AppDatabase? database}) : _db = database ?? AppDatabase();

  /// Storage key for the legacy v1 JSON document in SharedPreferences.
  static const String storageKey = 'palimpsest_archive_v1';

  static const String _metaVersion = 'version';
  static const String _metaCorrections = 'corrections';
  static const String _metaAccount = 'account';
  static const String _metaSettings = 'settings';
  static const String _metaImportState = 'importState';
  static const String _metaOnboardingSeen = 'onboardingSeen';

  final AppDatabase _db;

  /// Loads the stored archive, or null on a first run.
  ///
  /// Prefers the Drift store. When Drift holds no archive yet, a v1
  /// SharedPreferences document is migrated in (demo content
  /// dropped) and returned. Corrupt rows are skipped, never fatal:
  /// a single bad row must not lose the rest of the archive.
  ///
  /// Throws [ArchiveLoadException] when stored data exists but
  /// cannot be read — a failed database read, or a v1 document that
  /// is present but unparseable. The caller must NOT treat that as
  /// a first run.
  Future<ArchiveData?> load() async {
    try {
      if (await _hasDriftData()) {
        return await _loadFromDrift();
      }
    } catch (e) {
      // The database itself is unreachable (or its schema read
      // failed). We cannot tell whether it holds data, so we must
      // not report "no archive": the caller would persist an empty
      // document and prune every row. Throw and let the recovery
      // screen decide.
      debugPrint('ArchiveStore: Drift load failed: $e');
      throw const ArchiveLoadException(
        'The local archive database could not be read.',
      );
    }
    final migrated = await _migrateFromV1();
    if (migrated == null) {
      return null;
    }
    try {
      await save(migrated);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(storageKey);
    } catch (e) {
      // The migrated archive is returned either way; the old key
      // stays so the next launch retries the persist.
      debugPrint('ArchiveStore: could not persist migrated archive: $e');
    }
    return migrated;
  }

  /// Persists the whole archive document, transactionally.
  Future<void> save(ArchiveData data) async {
    await _db.transaction(() async {
      await _saveItems(data.items);
      await _saveStories(data.stories);
      await _saveLayers(data.layers);
      await _savePeople(data.people);
      await _savePlaces(data.places);
      await _saveVoiceNotes(data.voiceNotes);
      await _saveShareLinks(data.shareLinks);
      await _saveMoments(data.moments);
      await _saveMeta(data);
    });
  }

  /// Removes the stored archive (used by "delete local archive").
  /// Also removes any unmigrated v1 document.
  Future<void> clear() async {
    await _db.transaction(() async {
      await _db.delete(_db.items).go();
      await _db.delete(_db.stories).go();
      await _db.delete(_db.layers).go();
      await _db.delete(_db.people).go();
      await _db.delete(_db.places).go();
      await _db.delete(_db.voiceNotes).go();
      await _db.delete(_db.shareLinks).go();
      await _db.delete(_db.moments).go();
      await _db.delete(_db.meta).go();
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
  }

  Future<bool> _hasDriftData() async {
    final row = await (_db.select(_db.meta)
          ..where((t) => t.key.equals(_metaVersion)))
        .getSingleOrNull();
    return row != null;
  }

  Future<ArchiveData> _loadFromDrift() async {
    final itemRows = await _db.select(_db.items).get();
    final items = <MemoryItem>[];
    for (final row in itemRows) {
      final item = _tryParse(row.data, MemoryItem.fromJson);
      if (item != null) {
        items.add(item);
      }
    }
    final storyRows = await _db.select(_db.stories).get();
    final stories = <Story>[];
    for (final row in storyRows) {
      final story = _tryParse(row.data, Story.fromJson);
      if (story != null) {
        stories.add(story);
      }
    }
    final layerRows = await _db.select(_db.layers).get();
    final layers = <MemoryLayer>[];
    for (final row in layerRows) {
      final layer = _tryParse(row.data, MemoryLayer.fromJson);
      if (layer != null) {
        layers.add(layer);
      }
    }
    final personRows = await _db.select(_db.people).get();
    final people = <Person>[];
    for (final row in personRows) {
      final person = _tryParse(row.data, Person.fromJson);
      if (person != null) {
        people.add(person);
      }
    }
    final placeRows = await _db.select(_db.places).get();
    final places = <Place>[];
    for (final row in placeRows) {
      final place = _tryParse(row.data, Place.fromJson);
      if (place != null) {
        places.add(place);
      }
    }
    final voiceRows = await _db.select(_db.voiceNotes).get();
    final voiceNotes = <VoiceNote>[];
    for (final row in voiceRows) {
      final note = _tryParse(row.data, VoiceNote.fromJson);
      if (note != null) {
        voiceNotes.add(note);
      }
    }
    final linkRows = await _db.select(_db.shareLinks).get();
    final shareLinks = <ShareLink>[];
    for (final row in linkRows) {
      final link = _tryParse(row.data, ShareLink.fromJson);
      if (link != null) {
        shareLinks.add(link);
      }
    }
    final momentRows = await _db.select(_db.moments).get();
    final moments = <ReconstructedMoment>[];
    for (final row in momentRows) {
      final moment = _tryParse(row.data, ReconstructedMoment.fromJson);
      if (moment != null) {
        moments.add(moment);
      }
    }
    final metaRows = await _db.select(_db.meta).get();
    final meta = <String, String>{
      for (final row in metaRows) row.key: row.value,
    };
    return ArchiveData(
      version: int.tryParse(meta[_metaVersion] ?? '') ?? 2,
      stories: stories,
      items: items,
      layers: layers,
      people: people,
      places: places,
      voiceNotes: voiceNotes,
      shareLinks: shareLinks,
      moments: moments,
      corrections: _parseCorrections(meta[_metaCorrections]),
      account:
          _tryParse(meta[_metaAccount], AccountState.fromJson) ??
              AccountState.guest(),
      settings:
          _tryParse(meta[_metaSettings], ArchiveSettings.fromJson) ??
              const ArchiveSettings(),
      importState:
          _tryParse(meta[_metaImportState], ImportState.fromJson) ??
              const ImportState(
                total: 0,
                indexed: 0,
                status: ImportStatus.idle,
              ),
      onboardingSeen: meta[_metaOnboardingSeen] == 'true',
    );
  }

  Future<void> _saveItems(List<MemoryItem> items) async {
    await _prune(
      _db.items,
      items.map((i) => i.id).toSet(),
    );
    for (final item in items) {
      await _db.into(_db.items).insertOnConflictUpdate(
            ItemsCompanion(
              id: Value(item.id),
              data: Value(jsonEncode(item.toJson())),
              takenAt: Value(item.takenAt.millisecondsSinceEpoch),
              kind: Value(item.kind.name),
              isDemo: Value(item.isDemo),
              storyId: Value(item.storyId),
            ),
          );
    }
  }

  Future<void> _saveStories(List<Story> stories) async {
    await _prune(
      _db.stories,
      stories.map((s) => s.id).toSet(),
    );
    for (final story in stories) {
      await _db.into(_db.stories).insertOnConflictUpdate(
            StoriesCompanion(
              id: Value(story.id),
              data: Value(jsonEncode(story.toJson())),
              isDemo: Value(story.isDemo),
              startedAt: Value(story.startedAt.millisecondsSinceEpoch),
            ),
          );
    }
  }

  Future<void> _saveLayers(List<MemoryLayer> layers) async {
    await _prune(
      _db.layers,
      layers.map((l) => l.id).toSet(),
    );
    for (final layer in layers) {
      await _db.into(_db.layers).insertOnConflictUpdate(
            LayersCompanion(
              id: Value(layer.id),
              data: Value(jsonEncode(layer.toJson())),
              memoryId: Value(layer.memoryId),
            ),
          );
    }
  }

  Future<void> _savePeople(List<Person> people) async {
    await _prune(
      _db.people,
      people.map((p) => p.id).toSet(),
    );
    for (final person in people) {
      await _db.into(_db.people).insertOnConflictUpdate(
            PeopleCompanion(
              id: Value(person.id),
              data: Value(jsonEncode(person.toJson())),
            ),
          );
    }
  }

  Future<void> _savePlaces(List<Place> places) async {
    await _prune(
      _db.places,
      places.map((p) => p.id).toSet(),
    );
    for (final place in places) {
      await _db.into(_db.places).insertOnConflictUpdate(
            PlacesCompanion(
              id: Value(place.id),
              data: Value(jsonEncode(place.toJson())),
            ),
          );
    }
  }

  Future<void> _saveVoiceNotes(List<VoiceNote> notes) async {
    await _prune(
      _db.voiceNotes,
      notes.map((v) => v.id).toSet(),
    );
    for (final note in notes) {
      await _db.into(_db.voiceNotes).insertOnConflictUpdate(
            VoiceNotesCompanion(
              id: Value(note.id),
              data: Value(jsonEncode(note.toJson())),
              isDemo: Value(note.isDemo),
            ),
          );
    }
  }

  Future<void> _saveShareLinks(List<ShareLink> links) async {
    await _prune(
      _db.shareLinks,
      links.map((s) => s.id).toSet(),
    );
    for (final link in links) {
      await _db.into(_db.shareLinks).insertOnConflictUpdate(
            ShareLinksCompanion(
              id: Value(link.id),
              data: Value(jsonEncode(link.toJson())),
            ),
          );
    }
  }

  Future<void> _saveMoments(List<ReconstructedMoment> moments) async {
    await _prune(
      _db.moments,
      moments.map((m) => m.id).toSet(),
    );
    for (final moment in moments) {
      await _db.into(_db.moments).insertOnConflictUpdate(
            MomentsCompanion(
              id: Value(moment.id),
              data: Value(jsonEncode(moment.toJson())),
            ),
          );
    }
  }

  Future<void> _saveMeta(ArchiveData data) async {
    final entries = <String, String>{
      _metaVersion: data.version.toString(),
      _metaCorrections: jsonEncode(data.corrections),
      _metaAccount: jsonEncode(data.account.toJson()),
      _metaSettings: jsonEncode(data.settings.toJson()),
      _metaImportState: jsonEncode(data.importState.toJson()),
      _metaOnboardingSeen: data.onboardingSeen.toString(),
    };
    for (final entry in entries.entries) {
      await _db.into(_db.meta).insertOnConflictUpdate(
            MetaCompanion(
              key: Value(entry.key),
              value: Value(entry.value),
            ),
          );
    }
  }

  /// Deletes rows whose ids are no longer in the document. An empty
  /// id set clears the table (an empty `NOT IN ()` is invalid SQL).
  Future<void> _prune(
    TableInfo<Table, Object?> table,
    Set<String> keepIds,
  ) async {
    if (keepIds.isEmpty) {
      await _db.delete(table).go();
      return;
    }
    final idColumn = table.$columns
        .whereType<GeneratedColumn<String>>()
        .firstWhere((column) => column.name == 'id');
    await (_db.delete(table)..where((_) => idColumn.isNotIn(keepIds))).go();
  }

  /// Reads the legacy v1 SharedPreferences document and returns the
  /// migrated archive, or null when there is none. Seeded demo
  /// content is dropped: demo items, demo stories, demo voice notes,
  /// layers on dropped items, and moments whose visible items were
  /// all dropped. Items that survive but belonged to a dropped demo
  /// story are detached from it. People and places are kept —
  /// surviving items may reference them.
  ///
  /// Throws [ArchiveLoadException] when a v1 document is present
  /// but cannot be parsed: the data exists and may be the user's,
  /// so silently dropping it (first-run behaviour) would lose it.
  Future<ArchiveData?> _migrateFromV1() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null) {
      return null;
    }
    late final ArchiveData doc;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, Object?>) {
        throw const ArchiveLoadException(
          'The stored archive could not be read.',
        );
      }
      doc = ArchiveData.fromJson(decoded);
    } catch (e) {
      if (e is ArchiveLoadException) {
        rethrow;
      }
      throw const ArchiveLoadException(
        'The stored archive could not be read.',
      );
    }
    final droppedStoryIds = doc.stories
        .where((s) => s.isDemo)
        .map((s) => s.id)
        .toSet();
    final droppedItemIds = doc.items
        .where((i) => i.isDemo)
        .map((i) => i.id)
        .toSet();
    final items = doc.items
        .where((i) => !i.isDemo)
        .map((i) {
          if (i.storyId != null && droppedStoryIds.contains(i.storyId)) {
            return i.withoutStory();
          }
          return i;
        })
        .toList(growable: false);
    return ArchiveData(
      version: 2,
      stories: doc.stories
          .where((s) => !s.isDemo)
          .toList(growable: false),
      items: items,
      layers: doc.layers
          .where((l) => !droppedItemIds.contains(l.memoryId))
          .toList(growable: false),
      people: doc.people,
      places: doc.places,
      voiceNotes: doc.voiceNotes
          .where((v) => !v.isDemo)
          .toList(growable: false),
      shareLinks: doc.shareLinks,
      moments: doc.moments.where((m) {
        final visible = m.visibleItemIds;
        if (visible.isEmpty) {
          return true;
        }
        return visible.any((id) => !droppedItemIds.contains(id));
      }).toList(growable: false),
      corrections: doc.corrections,
      account: doc.account,
      settings: doc.settings,
      importState: doc.importState,
      onboardingSeen: doc.onboardingSeen,
    );
  }

  static T? _tryParse<T>(
    String? raw,
    T Function(Map<String, Object?>) fromJson,
  ) {
    if (raw == null) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, Object?>) {
        return null;
      }
      return fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  static Map<String, List<String>> _parseCorrections(String? raw) {
    if (raw == null) {
      return <String, List<String>>{};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return <String, List<String>>{};
      }
      return decoded.map(
        (key, value) => MapEntry(
          key.toString(),
          (value as List<dynamic>).map((e) => e.toString()).toList(),
        ),
      );
    } catch (_) {
      return <String, List<String>>{};
    }
  }
}
