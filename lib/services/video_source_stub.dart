import 'dart:typed_data';

import 'video_source.dart';

/// Creates a video source from [bytes]. Unsupported on platforms
/// without a video player.
Future<VideoSourceHandle> createVideoSource(
  Uint8List bytes,
  String mimeType,
) =>
    throw UnsupportedError('Video playback is not supported on this platform.');
