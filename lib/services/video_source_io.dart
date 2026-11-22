import 'dart:io';
import 'dart:typed_data';

import 'package:video_player/video_player.dart';

import 'video_source.dart';

/// Creates a video source from [bytes] on native platforms: the bytes
/// go to a temp file (the native player needs a file path) and the
/// file is deleted when the handle is released.
Future<VideoSourceHandle> createVideoSource(
  Uint8List bytes,
  String mimeType,
) async {
  final tempDir = await Directory.systemTemp.createTemp('palimpsest-video-');
  final file = File(
    '${tempDir.path}/clip-${DateTime.now().millisecondsSinceEpoch}',
  );
  await file.writeAsBytes(bytes, flush: true);
  final controller = VideoPlayerController.file(file);
  return VideoSourceHandle(
    controller: controller,
    release: () async {
      await controller.dispose();
      try {
        await file.delete();
        await tempDir.delete();
      } on FileSystemException {
        // Best effort: a leftover temp file is harmless.
      }
    },
  );
}
