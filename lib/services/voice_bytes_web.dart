import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Path to record into. The web recorder ignores the path (it keeps
/// the recording in memory and hands back a blob URL), so this is
/// only a placeholder.
String recordingPath() => 'voice-note.wav';

/// Reads the bytes of the finished recording: [path] is the blob URL
/// the recorder returned. The blob URL is revoked once read — the
/// bytes live in the BlobStore from here on.
Future<Uint8List> readRecordedBytes(String? path) async {
  if (path == null || path.isEmpty) {
    throw StateError('The recorder did not return an audio file.');
  }
  final response = await web.window.fetch(path.toJS).toDart;
  final buffer = await response.arrayBuffer().toDart;
  web.URL.revokeObjectURL(path);
  return buffer.toDart.asUint8List();
}
