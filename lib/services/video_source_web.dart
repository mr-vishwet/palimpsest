import 'dart:js_interop';
import 'dart:typed_data';

import 'package:video_player/video_player.dart';
import 'package:web/web.dart' as web;

import 'video_source.dart';

/// Creates a video source from [bytes] on web: the bytes become a
/// Blob URL, which the video_player web implementation plays
/// natively. The URL is revoked when the handle is released.
Future<VideoSourceHandle> createVideoSource(
  Uint8List bytes,
  String mimeType,
) async {
  final blob = web.Blob(
    <web.BlobPart>[bytes.toJS].toJS,
    web.BlobPropertyBag(type: mimeType),
  );
  final url = web.URL.createObjectURL(blob);
  final controller = VideoPlayerController.networkUrl(Uri.parse(url));
  return VideoSourceHandle(
    controller: controller,
    release: () async {
      await controller.dispose();
      web.URL.revokeObjectURL(url);
    },
  );
}
