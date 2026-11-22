import 'package:drift/drift.dart';

import 'db_connection_stub.dart'
    if (dart.library.js_interop) 'db_connection_web.dart'
    if (dart.library.io) 'db_connection_native.dart';

part 'app_database.g.dart';

/// One row per memory item: the id, the full item JSON, and the
/// columns the archive queries on (capture time, kind, demo flag,
/// story). The JSON column is the source of truth; the indexed
/// columns exist so timeline and story queries never scan JSON.
@TableIndex(name: 'items_taken_at_idx', columns: {#takenAt})
@TableIndex(name: 'items_kind_idx', columns: {#kind})
@TableIndex(name: 'items_is_demo_idx', columns: {#isDemo})
@TableIndex(name: 'items_story_idx', columns: {#storyId})
@DataClassName('ItemRow')
class Items extends Table {
  /// The item id (`frame-042`, `mem-…`).
  TextColumn get id => text()();

  /// The full memory-item JSON.
  TextColumn get data => text()();

  /// Capture time, milliseconds since epoch.
  IntColumn get takenAt => integer()();

  /// Media kind name (`photo`, `video`, `voiceNote`, `note`).
  TextColumn get kind => text()();

  /// True for seeded/demo content.
  BoolColumn get isDemo => boolean()();

  /// Story id, when the item belongs to a story.
  TextColumn get storyId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// One row per story. Chapters live inside the story JSON — the
/// archive model has no top-level chapters collection, so there is
/// no separate chapters table to keep in sync.
@TableIndex(name: 'stories_is_demo_idx', columns: {#isDemo})
@DataClassName('StoryRow')
class Stories extends Table {
  /// The story id.
  TextColumn get id => text()();

  /// The full story JSON, chapters included.
  TextColumn get data => text()();

  /// True for seeded/demo content.
  BoolColumn get isDemo => boolean()();

  /// Story start, milliseconds since epoch.
  IntColumn get startedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// One row per edit layer.
@TableIndex(name: 'layers_memory_idx', columns: {#memoryId})
@DataClassName('LayerRow')
class Layers extends Table {
  /// The layer id.
  TextColumn get id => text()();

  /// The full edit-layer JSON.
  TextColumn get data => text()();

  /// The memory this layer edits.
  TextColumn get memoryId => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// One row per person (face group).
@DataClassName('PersonRow')
class People extends Table {
  /// The person id.
  TextColumn get id => text()();

  /// The full person JSON.
  TextColumn get data => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// One row per place.
@DataClassName('PlaceRow')
class Places extends Table {
  /// The place id.
  TextColumn get id => text()();

  /// The full place JSON.
  TextColumn get data => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// One row per voice note.
@TableIndex(name: 'voice_notes_is_demo_idx', columns: {#isDemo})
@DataClassName('VoiceNoteRow')
class VoiceNotes extends Table {
  /// The voice note id.
  TextColumn get id => text()();

  /// The full voice-note JSON.
  TextColumn get data => text()();

  /// True for seeded/demo content.
  BoolColumn get isDemo => boolean()();

  @override
  Set<Column> get primaryKey => {id};
}

/// One row per share link.
@DataClassName('ShareLinkRow')
class ShareLinks extends Table {
  /// The share link id.
  TextColumn get id => text()();

  /// The full share-link JSON.
  TextColumn get data => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// One row per reconstructed moment.
@DataClassName('MomentRow')
class Moments extends Table {
  /// The moment id.
  TextColumn get id => text()();

  /// The full reconstructed-moment JSON.
  TextColumn get data => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Single-row settings: schema version, corrections, account,
/// settings, import state, onboarding flag — each under its own key.
@DataClassName('MetaRow')
class Meta extends Table {
  /// The meta key (`version`, `corrections`, `account`, `settings`,
  /// `importState`, `onboardingSeen`).
  TextColumn get key => text()();

  /// The JSON value for the key.
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// The Drift database for the archive.
///
/// One table per top-level collection, each row carrying the full
/// entity JSON plus the columns the archive queries on. The
/// The archive store owns the JSON encode/decode; this class owns the
/// schema and the platform connection (WASM on web, a file natively).
@DriftDatabase(
  tables: <Type>[
    Items,
    Stories,
    Layers,
    People,
    Places,
    VoiceNotes,
    ShareLinks,
    Moments,
    Meta,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Opens the platform database (WASM on web, a file natively).
  AppDatabase() : super(openDbConnection());

  /// Opens the database over an explicit executor — tests pass a
  /// `NativeDatabase.memory()` here.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;
}
