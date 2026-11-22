import 'blob_store.dart';

/// No blob store for this platform (neither web nor dart:io).
BlobStore createBlobStore() =>
    throw UnsupportedError('No blob store implementation for this platform');
