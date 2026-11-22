import 'dart:typed_data';

import 'package:idb_shim/idb_browser.dart';

import 'blob_store.dart';

/// Creates the web blob store (IndexedDB).
BlobStore createBlobStore() => _WebBlobStore();

class _WebBlobStore implements BlobStore {
  static const String _dbName = 'palimpsest_blobs';
  static const String _storeName = 'blobs';

  Database? _db;

  Future<Database> _open() async {
    final existing = _db;
    if (existing != null) {
      return existing;
    }
    final db = await idbFactoryBrowser.open(
      _dbName,
      version: 1,
      onUpgradeNeeded: (event) {
        event.database.createObjectStore(_storeName);
      },
    );
    _db = db;
    return db;
  }

  @override
  Future<String> put(Uint8List bytes) async {
    final id = BlobStore.idFor(bytes);
    final db = await _open();
    final txn = db.transaction(_storeName, idbModeReadWrite);
    await txn.objectStore(_storeName).put(bytes, id);
    await txn.completed;
    return id;
  }

  @override
  Future<Uint8List?> get(String id) async {
    final db = await _open();
    final txn = db.transaction(_storeName, idbModeReadOnly);
    final value = await txn.objectStore(_storeName).getObject(id);
    await txn.completed;
    if (value is Uint8List) {
      return value;
    }
    if (value is List<int>) {
      return Uint8List.fromList(value);
    }
    return null;
  }

  @override
  Future<void> delete(String id) async {
    final db = await _open();
    final txn = db.transaction(_storeName, idbModeReadWrite);
    await txn.objectStore(_storeName).delete(id);
    await txn.completed;
  }

  @override
  Future<int> totalBytes() async {
    final db = await _open();
    final txn = db.transaction(_storeName, idbModeReadOnly);
    final all = await txn.objectStore(_storeName).getAll();
    await txn.completed;
    var total = 0;
    for (final value in all) {
      if (value is List<int>) {
        total += value.length;
      }
    }
    return total;
  }
}
