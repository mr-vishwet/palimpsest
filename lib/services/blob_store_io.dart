import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import 'blob_store.dart';

/// Creates the native blob store (files under the app documents dir).
BlobStore createBlobStore() => _IoBlobStore();

class _IoBlobStore implements BlobStore {
  Directory? _dir;

  Future<Directory> _blobsDir() async {
    final existing = _dir;
    if (existing != null) {
      return existing;
    }
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/palimpsest_blobs');
    await dir.create(recursive: true);
    _dir = dir;
    return dir;
  }

  Future<File> _fileFor(String id) async =>
      File('${(await _blobsDir()).path}/$id.bin');

  @override
  Future<String> put(Uint8List bytes) async {
    final id = BlobStore.idFor(bytes);
    final file = await _fileFor(id);
    if (!await file.exists()) {
      await file.writeAsBytes(bytes);
    }
    return id;
  }

  @override
  Future<Uint8List?> get(String id) async {
    final file = await _fileFor(id);
    if (!await file.exists()) {
      return null;
    }
    return file.readAsBytes();
  }

  @override
  Future<void> delete(String id) async {
    final file = await _fileFor(id);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<int> totalBytes() async {
    final dir = await _blobsDir();
    var total = 0;
    await for (final entity in dir.list()) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }
}
