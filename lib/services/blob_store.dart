import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'blob_store_stub.dart'
    if (dart.library.js_interop) 'blob_store_web.dart'
    if (dart.library.io) 'blob_store_io.dart' as platform;

/// Content-addressed local store for original file bytes and
/// thumbnails.
///
/// Blob ids are the SHA-256 hex of the bytes, so storing the same
/// bytes twice is a no-op and ids are stable. On the web the bytes
/// live in IndexedDB; natively they live as files under the app
/// documents directory. Blobs are NEVER base64'd into
/// SharedPreferences — that path corrupts large files and bloats
/// the settings store.
///
/// The metadata store (Drift) holds only the blob id; the bytes
/// live here. Deleting an item deletes its blobs (the archive
/// controller handles that).
abstract class BlobStore {
  /// Creates the platform blob store.
  factory BlobStore() => platform.createBlobStore();

  /// The id the given bytes would be stored under (SHA-256 hex).
  static String idFor(Uint8List bytes) => sha256.convert(bytes).toString();

  /// Stores [bytes], returning its id. Idempotent: storing the same
  /// bytes again returns the same id without duplicating storage.
  Future<String> put(Uint8List bytes);

  /// Returns the bytes for [id], or null when no blob has that id.
  Future<Uint8List?> get(String id);

  /// Deletes the blob with [id]. A no-op when it does not exist.
  Future<void> delete(String id);

  /// Total bytes stored across all blobs.
  Future<int> totalBytes();
}

/// An in-memory blob store, for tests and previews. Nothing here is
/// persisted.
class MemoryBlobStore implements BlobStore {
  final Map<String, Uint8List> _blobs = <String, Uint8List>{};

  @override
  Future<String> put(Uint8List bytes) async {
    final id = BlobStore.idFor(bytes);
    _blobs[id] = bytes;
    return id;
  }

  @override
  Future<Uint8List?> get(String id) async => _blobs[id];

  @override
  Future<void> delete(String id) async {
    _blobs.remove(id);
  }

  @override
  Future<int> totalBytes() async =>
      _blobs.values.fold<int>(0, (sum, bytes) => sum + bytes.length);
}
