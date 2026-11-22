import 'dart:typed_data';

import 'package:video_player/video_player.dart';

import 'video_source_platform.dart' as platform;

/// A loaded video: its controller plus the cleanup for the underlying
/// blob URL (web) or temp file (native).
class VideoSourceHandle {
  /// Creates a video handle.
  const VideoSourceHandle({
    required this.controller,
    required this.release,
  });

  /// The player controller. Call [VideoPlayerController.initialize]
  /// before showing it.
  final VideoPlayerController controller;

  /// Disposes the controller and releases the blob URL / temp file.
  /// Always call this instead of disposing the controller directly.
  final Future<void> Function() release;
}

/// Builds a [VideoPlayerController] from in-memory bytes.
///
/// Web: the bytes become a Blob URL (`URL.createObjectURL`) and the
/// video_player web implementation plays it natively — no data URI,
/// so large clips play without base64 bloat. Native: the bytes go to
/// a temp file and the file player is used. Either way the bytes come
/// from the BlobStore, never from a network fetch: playback is fully
/// local.
abstract final class VideoSource {
  /// Creates a controller for [bytes] of MIME type [mimeType].
  /// The caller owns the handle and must call [VideoSourceHandle.release].
  static Future<VideoSourceHandle> fromBytes(
    Uint8List bytes,
    String mimeType,
  ) =>
      platform.createVideoSource(bytes, mimeType);
}
