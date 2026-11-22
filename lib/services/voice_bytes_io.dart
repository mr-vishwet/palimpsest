import 'dart:io';
import 'dart:typed_data';

/// Path to record into: a temp file, deleted once its bytes are in
/// the BlobStore.
String recordingPath() =>
    '${Directory.systemTemp.path}/palimpsest-voice-'
    '${DateTime.now().millisecondsSinceEpoch}.wav';

/// Reads the bytes of the finished recording at [path] and deletes
/// the temp file — the bytes live in the BlobStore from here on.
Future<Uint8List> readRecordedBytes(String? path) async {
  if (path == null || path.isEmpty) {
    throw StateError('The recorder did not return an audio file.');
  }
  final file = File(path);
  final bytes = await file.readAsBytes();
  try {
    await file.delete();
  } on FileSystemException {
    // Best effort: a leftover temp file is harmless.
  }
  return bytes;
}
