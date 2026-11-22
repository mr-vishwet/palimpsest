import 'dart:typed_data';

/// Path to record into. Unused on platforms without recording.
String recordingPath() =>
    throw UnsupportedError('Recording is not supported on this platform.');

/// Reads the bytes of the finished recording at [path].
Future<Uint8List> readRecordedBytes(String? path) =>
    throw UnsupportedError('Recording is not supported on this platform.');
