import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../engine/archive_index.dart';
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
import '../services/archive_store.dart';
import '../services/blob_store.dart';
import '../services/demo_media_loader.dart';
import '../services/import_service.dart';

/// The archive's state: one [ArchiveData] document, mutated through
/// methods that persist on every change.
///
/// Every mutation writes through to [ArchiveStore] and notifies
/// listeners, so screens always show stored state. Edits to a memory
/// write a [MemoryLayer] — nothing is ever overwritten; the older
/// layers stay visible beneath.
class ArchiveController extends ChangeNotifier {
  /// Creates the controller over the loaded (or empty) archive.
  /// Pass [blobStore] in tests; otherwise the platform store is used.
  /// Stored counts are recomputed from the items on the way in, so a
  /// document written by an older build never shows stale numbers.
  ArchiveController({
    required ArchiveStore store,
    required ArchiveData initialData,
    BlobStore? blobStore,
  })  : _store = store,
        _data = _withDerivedCounts(initialData),
        _blobStore = blobStore ?? BlobStore();

  final ArchiveStore _store;
  final BlobStore _blobStore;
  ArchiveData _data;

  /// The whole archive document.
  ArchiveData get data => _data;

  /// The blob store holding imported originals and thumbnails.
  BlobStore get blobStore => _blobStore;

  /// Stories in the archive.
  List<Story> get stories => _data.stories;

  /// Indexed memory items.
  List<MemoryItem> get items => _data.items;

  /// Edit layers across all memories.
  List<MemoryLayer> get layers => _data.layers;

  /// People (face groups).
  List<Person> get people => _data.people;

  /// Places on the schematic map.
  List<Place> get places => _data.places;

  /// Voice notes.
  List<VoiceNote> get voiceNotes => _data.voiceNotes;

  /// Active share links.
  List<ShareLink> get shareLinks => _data.shareLinks;

  /// Reconstructed moments, newest first.
  List<ReconstructedMoment> get moments => _data.moments;

  /// Account state.
  AccountState get account => _data.account;

  /// Archive settings.
  ArchiveSettings get settings => _data.settings;

  /// Import queue state.
  ImportState get importState => _data.importState;

  /// Demo-media items currently in the archive.
  int get demoItemCount => _data.items.where((i) => i.isDemo).length;

  /// True when any demo-media content is loaded.
  bool get hasDemoData => demoItemCount > 0;

  /// The most recent reconstructed moment, if any.
  ReconstructedMoment? get latestMoment =>
      _data.moments.isEmpty ? null : _data.moments.first;

  /// Finds a story by id, or null.
  Story? storyById(String id) =>
      _data.stories.where((s) => s.id == id).firstOrNull;

  /// Finds a memory item by id, or null.
  MemoryItem? itemById(String id) =>
      _data.items.where((i) => i.id == id).firstOrNull;

  /// Finds a voice note by id, or null.
  VoiceNote? voiceNoteById(String id) =>
      _data.voiceNotes.where((v) => v.id == id).firstOrNull;

  /// Finds a reconstructed moment by id, or null.
  ReconstructedMoment? momentById(String id) =>
      _data.moments.where((m) => m.id == id).firstOrNull;

  /// Finds a person by id, or null.
  Person? personById(String id) =>
      _data.people.where((p) => p.id == id).firstOrNull;

  /// Finds a place by id, or null.
  Place? placeById(String id) =>
      _data.places.where((p) => p.id == id).firstOrNull;

  /// Items in a story, chronological (the order a story plays).
  List<MemoryItem> itemsInStory(String storyId) {
    final mine =
        _data.items.where((i) => i.storyId == storyId).toList(growable: false);
    mine.sort((a, b) => a.takenAt.compareTo(b.takenAt));
    return mine;
  }

  /// Items in a story with no chapter yet — waiting to be placed.
  List<MemoryItem> unplacedItems(String storyId) => _data.items
      .where((i) => i.storyId == storyId && i.chapterId == null)
      .toList(growable: false);

  /// Layers for one memory, newest first.
  List<MemoryLayer> layersFor(String memoryId) =>
      LayerStack.forMemory(_data.layers, memoryId);

  /// The current caption of a memory: the newest caption layer, or the
  /// stored note.
  String captionFor(MemoryItem item) => LayerStack.currentValue(
        layersFor(item.id),
        LayerKind.caption,
        item.note ?? '',
      );

  /// Marks the first-launch flow complete.
  void markOnboardingSeen() {
    _update(_data.copyWith(onboardingSeen: true));
  }

  /// Replaces the whole settings object.
  void updateSettings(ArchiveSettings next) {
    _update(_data.copyWith(settings: next));
  }

  /// Replaces the whole account state.
  void updateAccount(AccountState next) {
    _update(_data.copyWith(account: next));
  }

  /// Edits a memory's caption, writing a layer that keeps the old
  /// caption visible beneath.
  void updateCaption(String itemId, String caption) {
    final item = itemById(itemId);
    if (item == null) {
      return;
    }
    final previous = captionFor(item);
    if (previous == caption) {
      return;
    }
    _update(
      _data.copyWith(
        items: _replaceItem(item.copyWith(note: caption)),
        layers: <MemoryLayer>[
          ..._data.layers,
          MemoryLayer(
            id: _layerId(itemId),
            memoryId: itemId,
            kind: LayerKind.caption,
            summary: 'Caption changed',
            previousValue: previous,
            newValue: caption,
            createdAt: DateTime.now(),
            isDemo: false,
          ),
        ],
      ),
    );
  }

  /// Adds a tag to a memory, writing a layer.
  void addTag(String itemId, String tag) {
    final item = itemById(itemId);
    final clean = tag.trim().toLowerCase();
    if (item == null || clean.isEmpty || item.tags.contains(clean)) {
      return;
    }
    final next = <String>[...item.tags, clean];
    _update(
      _data.copyWith(
        items: _replaceItem(item.copyWith(tags: next)),
        layers: <MemoryLayer>[
          ..._data.layers,
          MemoryLayer(
            id: _layerId(itemId),
            memoryId: itemId,
            kind: LayerKind.tags,
            summary: "Tag '$clean' added",
            previousValue: item.tags.join(', '),
            newValue: next.join(', '),
            createdAt: DateTime.now(),
            isDemo: false,
          ),
        ],
      ),
    );
  }

  /// Removes a tag from a memory, writing a layer.
  void removeTag(String itemId, String tag) {
    final item = itemById(itemId);
    if (item == null || !item.tags.contains(tag)) {
      return;
    }
    final next = item.tags.where((t) => t != tag).toList(growable: false);
    _update(
      _data.copyWith(
        items: _replaceItem(item.copyWith(tags: next)),
        layers: <MemoryLayer>[
          ..._data.layers,
          MemoryLayer(
            id: _layerId(itemId),
            memoryId: itemId,
            kind: LayerKind.tags,
            summary: "Tag '$tag' removed",
            previousValue: item.tags.join(', '),
            newValue: next.join(', '),
            createdAt: DateTime.now(),
            isDemo: false,
          ),
        ],
      ),
    );
  }

  /// Makes [itemId] the cover of its story, writing a layer. Any other
  /// cover in the same story is cleared.
  void setCover(String itemId) {
    final item = itemById(itemId);
    if (item == null || item.storyId == null) {
      return;
    }
    final previousCover = _data.items
        .where((i) => i.storyId == item.storyId && i.isCover)
        .firstOrNull;
    final nextItems = _data.items.map((i) {
      if (i.storyId != item.storyId) {
        return i;
      }
      if (i.id == itemId) {
        return i.copyWith(isCover: true);
      }
      if (i.isCover) {
        return i.copyWith(isCover: false);
      }
      return i;
    }).toList(growable: false);
    _update(
      _data.copyWith(
        items: nextItems,
        layers: <MemoryLayer>[
          ..._data.layers,
          MemoryLayer(
            id: _layerId(itemId),
            memoryId: itemId,
            kind: LayerKind.cover,
            summary: 'Made story cover',
            previousValue: previousCover?.title ?? 'None',
            newValue: item.title,
            createdAt: DateTime.now(),
            isDemo: false,
          ),
        ],
      ),
    );
  }

  /// Reverts the newest layer of its kind on a memory, revealing the
  /// value beneath. Buried layers cannot be reverted.
  void revertLayer(String layerId) {
    final layer = _data.layers.where((l) => l.id == layerId).firstOrNull;
    if (layer == null) {
      return;
    }
    final mine = layersFor(layer.memoryId);
    final reverted = LayerStack.revert(mine, layerId);
    if (reverted.length == mine.length) {
      return;
    }
    final item = itemById(layer.memoryId);
    var nextItems = _data.items;
    if (item != null && layer.kind == LayerKind.caption) {
      final restored = LayerStack.currentValue(
        reverted,
        LayerKind.caption,
        '',
      );
      nextItems = _replaceItem(
        item.copyWith(note: restored.isEmpty ? null : restored),
      );
    }
    if (item != null && layer.kind == LayerKind.tags) {
      final restored = LayerStack.currentValue(reverted, LayerKind.tags, '');
      nextItems = _replaceItem(
        item.copyWith(
          tags: restored.isEmpty
              ? const <String>[]
              : restored.split(', ').toList(growable: false),
        ),
      );
    }
    final others =
        _data.layers.where((l) => l.memoryId != layer.memoryId).toList();
    _update(
      _data.copyWith(items: nextItems, layers: [...others, ...reverted]),
    );
  }

  /// Names (or renames) a face group.
  void renamePerson(String personId, String name) {
    final person = personById(personId);
    final clean = name.trim();
    if (person == null || clean.isEmpty) {
      return;
    }
    _update(
      _data.copyWith(
        people: _data.people
            .map((p) => p.id == personId ? p.copyWith(name: clean) : p)
            .toList(growable: false),
      ),
    );
  }

  /// Reorders a story's chapters to the given order.
  void reorderChapters(String storyId, List<Chapter> reordered) {
    final story = storyById(storyId);
    if (story == null) {
      return;
    }
    final withOrder = <Chapter>[];
    for (var i = 0; i < reordered.length; i++) {
      withOrder.add(reordered[i].copyWith(order: i));
    }
    _update(
      _data.copyWith(
        stories: _replaceStory(story.copyWith(chapters: withOrder)),
      ),
    );
  }

  /// Edits a chapter's title, caption or cover frame.
  void updateChapter(
    String storyId,
    String chapterId, {
    String? title,
    String? caption,
    String? coverFrameId,
  }) {
    final story = storyById(storyId);
    if (story == null) {
      return;
    }
    final next = story.chapters.map((chapter) {
      if (chapter.id != chapterId) {
        return chapter;
      }
      return chapter.copyWith(
        title: title,
        caption: caption,
        coverFrameId: coverFrameId,
      );
    }).toList(growable: false);
    _update(
      _data.copyWith(
        stories: _replaceStory(story.copyWith(chapters: next)),
      ),
    );
  }

  /// Places an unplaced item into a chapter.
  void placeItemInChapter(String itemId, String chapterId) {
    final item = itemById(itemId);
    if (item == null) {
      return;
    }
    _update(_data.copyWith(items: _replaceItem(item.copyWith(chapterId: chapterId))));
  }

  /// Attaches a voice note to a story, or detaches it when [storyId]
  /// is null. (Null is a real value here, not "keep" — the note is
  /// rebuilt rather than copied so detach works.)
  void attachVoiceNote(String noteId, String? storyId) {
    final note = voiceNoteById(noteId);
    if (note == null) {
      return;
    }
    _update(
      _data.copyWith(
        voiceNotes: _data.voiceNotes
            .map(
              (v) => v.id == noteId
                  ? VoiceNote(
                      id: v.id,
                      title: v.title,
                      durationSeconds: v.durationSeconds,
                      transcript: v.transcript,
                      takenAt: v.takenAt,
                      waveform: v.waveform,
                      storyId: storyId,
                      attachedMemoryId: v.attachedMemoryId,
                      blobId: v.blobId,
                      mimeType: v.mimeType,
                      isDemo: v.isDemo,
                    )
                  : v,
            )
            .toList(growable: false),
      ),
    );
  }

  /// Adds a reconstructed moment, replacing any earlier moment for the
  /// same question (one answer per question — the newest wins).
  void addMoment(ReconstructedMoment moment) {
    final normalized = ArchiveIndex.normalize(moment.query);
    final kept = _data.moments
        .where((m) => ArchiveIndex.normalize(m.query) != normalized)
        .toList(growable: false);
    _update(
      _data.copyWith(moments: <ReconstructedMoment>[moment, ...kept]),
    );
  }

  /// Removes an item from a moment and teaches the archive: the same
  /// question will not bring it back.
  void removeItemFromMoment(String momentId, String itemId) {
    final moment = momentById(momentId);
    if (moment == null || moment.removedIds.contains(itemId)) {
      return;
    }
    final normalized = ArchiveIndex.normalize(moment.query);
    final corrections = Map<String, List<String>>.of(_data.corrections);
    corrections[normalized] = <String>[
      ...?corrections[normalized],
      itemId,
    ];
    final nextMoment = moment.copyWith(
      removedIds: <String>[...moment.removedIds, itemId],
    );
    _update(
      _data.copyWith(
        moments: _data.moments
            .map((m) => m.id == momentId ? nextMoment : m)
            .toList(growable: false),
        corrections: corrections,
      ),
    );
  }

  /// Saves a reconstructed moment as a story with one chapter per
  /// anchor find. Returns the new story id.
  String saveMomentAsStory(String momentId) {
    final moment = momentById(momentId);
    if (moment == null) {
      return '';
    }
    if (moment.savedAsStoryId != null) {
      return moment.savedAsStoryId!;
    }
    final storyId = 'story-${DateTime.now().millisecondsSinceEpoch}';
    final visible = moment.visibleItemIds
        .map(itemById)
        .whereType<MemoryItem>()
        .toList(growable: false);
    final photos = visible.where((i) => i.kind == MediaKind.photo).length;
    final videos = visible.where((i) => i.kind == MediaKind.video).length;
    final story = Story(
      id: storyId,
      title: moment.title,
      place: 'From a question',
      durationLabel: 'A moment',
      days: 0,
      peopleCount: visible
          .expand((i) => i.personIds)
          .toSet()
          .length,
      chapters: <Chapter>[
        Chapter(
          id: '$storyId-ch1',
          storyId: storyId,
          title: moment.title,
          caption: 'Rebuilt from the question: "${moment.query}"',
          day: 0,
          photoCount: photos,
          videoCount: videos,
          playSeconds: 0,
          order: 0,
          coverFrameId: visible.isEmpty ? null : visible.first.id,
        ),
      ],
      photoCount: photos,
      videoCount: videos,
      coverArt: 'moment',
      startedAt: visible.isEmpty
          ? DateTime.now()
          : visible
              .map((i) => i.takenAt)
              .reduce((a, b) => a.isBefore(b) ? a : b),
      isDemo: false,
    );
    final movedItems = _data.items.map((item) {
      if (moment.visibleItemIds.contains(item.id) && item.storyId == null) {
        return item.copyWith(storyId: storyId, chapterId: '$storyId-ch1');
      }
      return item;
    }).toList(growable: false);
    final nextMoment = moment.copyWith(savedAsStoryId: storyId);
    _update(
      _data.copyWith(
        stories: <Story>[..._data.stories, story],
        items: movedItems,
        moments: _data.moments
            .map((m) => m.id == momentId ? nextMoment : m)
            .toList(growable: false),
      ),
    );
    return storyId;
  }

  /// Creates a view-only share link for a story. Returns null when
  /// sharing is unavailable (guest without an account, or offline
  /// mode) — the caller routes to the upgrade prompt instead.
  ShareLink? createShareLink(String storyId, {bool downloadsAllowed = false}) {
    if (!_data.account.isSignedIn || _data.settings.offlineMode) {
      return null;
    }
    final now = DateTime.now();
    final code = _linkCode(storyId, now);
    final link = ShareLink(
      id: 'link-${now.millisecondsSinceEpoch}',
      storyId: storyId,
      code: code,
      createdAt: now,
      expiresAt:
          now.add(const Duration(days: AppConstants.shareLinkExpiryDays)),
      downloadsAllowed: downloadsAllowed,
    );
    _update(
      _data.copyWith(shareLinks: <ShareLink>[..._data.shareLinks, link]),
    );
    return link;
  }

  /// Revokes a share link.
  void revokeShareLink(String linkId) {
    _update(
      _data.copyWith(
        shareLinks: _data.shareLinks
            .where((link) => link.id != linkId)
            .toList(growable: false),
      ),
    );
  }

  /// Deletes a memory for real: the item and its layers leave the
  /// index, and its stored blobs (original + thumbnail) are deleted.
  /// Blob cleanup is best-effort — a failed delete never blocks the
  /// removal, and orphaned blobs are harmless.
  void deleteItem(String itemId) {
    final item = itemById(itemId);
    if (item != null) {
      unawaited(_deleteBlobs(item.blobId, item.thumbBlobId));
    }
    _update(
      _data.copyWith(
        items: _data.items.where((i) => i.id != itemId).toList(growable: false),
        layers: _data.layers
            .where((l) => l.memoryId != itemId)
            .toList(growable: false),
      ),
    );
  }

  /// Adds freshly imported items to the archive, skipping any whose
  /// checksum is already present — re-importing the same file is a
  /// no-op. Returns the number of items actually added.
  int addImportedItems(List<MemoryItem> items) {
    if (items.isEmpty) {
      return 0;
    }
    final known = _data.items.map((i) => i.checksum).toSet();
    final fresh = items
        .where((i) => !known.contains(i.checksum))
        .toList(growable: false);
    if (fresh.isEmpty) {
      return 0;
    }
    _update(
      _data.copyWith(items: <MemoryItem>[..._data.items, ...fresh]),
    );
    return fresh.length;
  }

  /// Records a finished import batch in the import queue state.
  void recordImport({required int total, required int imported}) {
    final state = _data.importState;
    _update(
      _data.copyWith(
        importState: state.copyWith(
          total: state.total + total,
          indexed: state.indexed + imported,
          status: ImportStatus.done,
        ),
      ),
    );
  }

  /// Replaces an item with an updated copy. Used by media probing to
  /// write back duration/dimensions after first playback. A no-op
  /// when the id is unknown.
  void updateItem(MemoryItem next) {
    if (itemById(next.id) == null) {
      return;
    }
    _update(_data.copyWith(items: _replaceItem(next)));
  }

  /// Writes back probed media dimensions/duration for an item
  /// (video metadata on first playback). The aspect label is
  /// recomputed from the probed dimensions so the tile stays honest.
  /// A no-op when the id is unknown.
  void updateItemMedia(
    String itemId, {
    int? durationSeconds,
    int? widthPx,
    int? heightPx,
  }) {
    final item = itemById(itemId);
    if (item == null) {
      return;
    }
    final nextWidth = widthPx ?? item.widthPx;
    final nextHeight = heightPx ?? item.heightPx;
    _update(
      _data.copyWith(
        items: _replaceItem(
          item.copyWith(
            durationSeconds: durationSeconds ?? item.durationSeconds,
            widthPx: nextWidth,
            heightPx: nextHeight,
            aspectRatio: ImportService.aspectLabelFor(nextWidth, nextHeight),
          ),
        ),
      ),
    );
  }

  /// Adds a place to the archive, replacing any place with the same
  /// id (an edit that re-saves is an update, not a duplicate).
  void addPlace(Place place) {
    final exists = placeById(place.id) != null;
    _update(
      _data.copyWith(
        places: exists
            ? _data.places
                .map((p) => p.id == place.id ? place : p)
                .toList(growable: false)
            : <Place>[..._data.places, place],
      ),
    );
  }

  /// Renames a place. A no-op when the id is unknown.
  void renamePlace(String placeId, String name) {
    final place = placeById(placeId);
    if (place == null) {
      return;
    }
    _update(
      _data.copyWith(
        places: _data.places
            .map((p) => p.id == placeId ? p.copyWith(name: name) : p)
            .toList(growable: false),
      ),
    );
  }

  /// Adds a recorded voice note and its archive item together.
  /// Either side replaces an existing entry with the same id.
  void addVoiceNote(VoiceNote note, MemoryItem item) {
    final notes = voiceNoteById(note.id) == null
        ? <VoiceNote>[..._data.voiceNotes, note]
        : _data.voiceNotes
            .map((v) => v.id == note.id ? note : v)
            .toList(growable: false);
    final items = itemById(item.id) == null
        ? <MemoryItem>[..._data.items, item]
        : _replaceItem(item);
    _update(_data.copyWith(voiceNotes: notes, items: items));
  }

  /// Loads the bundled demo media through the real import pipeline
  /// (see [DemoMediaLoader]). Re-running is safe: files already in
  /// the archive dedup by checksum. Returns the load result.
  Future<DemoMediaLoadResult> loadDemoMedia() {
    final loader = DemoMediaLoader(
      importer: ImportService(blobs: _blobStore),
    );
    return loader.loadInto(this);
  }

  /// Deletes all demo-media content: demo items (and their blobs and
  /// layers), demo stories, demo voice notes, and moments whose
  /// visible items were all demo. User content is never touched.
  /// Returns the number of demo items removed.
  int clearDemoData() {
    final demoItems =
        _data.items.where((i) => i.isDemo).toList(growable: false);
    final demoItemIds = demoItems.map((i) => i.id).toSet();
    for (final item in demoItems) {
      unawaited(_deleteBlobs(item.blobId, item.thumbBlobId));
    }
    final stories = <Story>[];
    for (final story in _data.stories) {
      if (story.isDemo) {
        continue;
      }
      // A surviving story keeps its chapters, but a cover frame
      // pointing at a deleted demo item is cleared (Chapter.copyWith
      // cannot null the cover, so the chapter is rebuilt).
      final chapters = story.chapters.map((chapter) {
        if (chapter.coverFrameId == null ||
            !demoItemIds.contains(chapter.coverFrameId)) {
          return chapter;
        }
        return Chapter(
          id: chapter.id,
          storyId: chapter.storyId,
          title: chapter.title,
          caption: chapter.caption,
          day: chapter.day,
          photoCount: chapter.photoCount,
          videoCount: chapter.videoCount,
          playSeconds: chapter.playSeconds,
          order: chapter.order,
        );
      }).toList(growable: false);
      stories.add(story.copyWith(chapters: chapters));
    }
    final moments = _data.moments.where((moment) {
      final visible = moment.visibleItemIds;
      if (visible.isEmpty) {
        return true;
      }
      return visible.any((id) => !demoItemIds.contains(id));
    }).toList(growable: false);
    _update(
      _data.copyWith(
        items:
            _data.items.where((i) => !i.isDemo).toList(growable: false),
        stories: stories,
        layers: _data.layers
            .where((l) => !demoItemIds.contains(l.memoryId))
            .toList(growable: false),
        voiceNotes: _data.voiceNotes
            .where((v) => !v.isDemo)
            .toList(growable: false),
        moments: moments,
      ),
    );
    return demoItems.length;
  }

  String _layerId(String itemId) =>
      'layer-$itemId-${DateTime.now().millisecondsSinceEpoch}';

  String _linkCode(String storyId, DateTime now) {
    final raw = '$storyId|${now.millisecondsSinceEpoch}';
    var hash = 0;
    for (final unit in raw.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    const alphabet = 'abcdefghjkmnpqrstuvwxyz23456789';
    final buffer = StringBuffer();
    var value = hash;
    for (var i = 0; i < 8; i++) {
      buffer.write(alphabet[value % alphabet.length]);
      value ~/= alphabet.length;
    }
    return buffer.toString();
  }

  List<MemoryItem> _replaceItem(MemoryItem next) => _data.items
      .map((i) => i.id == next.id ? next : i)
      .toList(growable: false);

  List<Story> _replaceStory(Story next) => _data.stories
      .map((s) => s.id == next.id ? next : s)
      .toList(growable: false);

  void _update(ArchiveData next) {
    _data = _withDerivedCounts(next);
    _persist();
    notifyListeners();
  }

  /// Recomputes every stored count from the items: story and chapter
  /// photo/video counts and play lengths, story people counts, and
  /// person/place photo counts. Stored counts are a cache, never the
  /// truth — recomputing on every mutation keeps screens honest even
  /// when items move, are deleted, or arrive with stale counts from
  /// an older build. Play length is 4 s per photo (the story player's
  /// dwell) plus recorded durations for videos and voice notes.
  static ArchiveData _withDerivedCounts(ArchiveData data) {
    final byStory = <String, List<MemoryItem>>{};
    final byChapter = <String, List<MemoryItem>>{};
    for (final item in data.items) {
      final storyId = item.storyId;
      if (storyId != null) {
        (byStory[storyId] ??= <MemoryItem>[]).add(item);
        final chapterId = item.chapterId;
        if (chapterId != null) {
          (byChapter[chapterId] ??= <MemoryItem>[]).add(item);
        }
      }
    }

    int playSecondsFor(List<MemoryItem> items) {
      var seconds = 0;
      for (final item in items) {
        switch (item.kind) {
          case MediaKind.photo:
            seconds += 4;
          case MediaKind.video:
          case MediaKind.voiceNote:
            seconds += item.durationSeconds ?? 0;
          case MediaKind.note:
            break;
        }
      }
      return seconds;
    }

    int photosIn(List<MemoryItem> items) =>
        items.where((i) => i.kind == MediaKind.photo).length;
    int videosIn(List<MemoryItem> items) =>
        items.where((i) => i.kind == MediaKind.video).length;

    final stories = data.stories.map((story) {
      final storyItems = byStory[story.id] ?? const <MemoryItem>[];
      final chapters = story.chapters.map((chapter) {
        final chapterItems = byChapter[chapter.id] ?? const <MemoryItem>[];
        return chapter.copyWith(
          photoCount: photosIn(chapterItems),
          videoCount: videosIn(chapterItems),
          playSeconds: playSecondsFor(chapterItems),
        );
      }).toList(growable: false);
      return story.copyWith(
        chapters: chapters,
        photoCount: photosIn(storyItems),
        videoCount: videosIn(storyItems),
        peopleCount:
            storyItems.expand((i) => i.personIds).toSet().length,
      );
    }).toList(growable: false);

    final people = data.people.map((person) {
      return person.copyWith(
        photoCount: data.items
            .where(
              (i) =>
                  i.kind == MediaKind.photo &&
                  i.personIds.contains(person.id),
            )
            .length,
      );
    }).toList(growable: false);

    final places = data.places.map((place) {
      return place.copyWith(
        photoCount: data.items
            .where((i) => i.kind == MediaKind.photo && i.placeId == place.id)
            .length,
      );
    }).toList(growable: false);

    return data.copyWith(
      stories: stories,
      people: people,
      places: places,
    );
  }

  void _persist() {
    unawaited(_store.save(_data));
  }

  Future<void> _deleteBlobs(String? blobId, String? thumbBlobId) async {
    try {
      if (blobId != null) {
        await _blobStore.delete(blobId);
      }
      if (thumbBlobId != null) {
        await _blobStore.delete(thumbBlobId);
      }
    } catch (_) {
      // Best-effort cleanup (see deleteItem).
    }
  }
}
