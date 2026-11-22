/// Platform video sources: blob URLs on web, temp files on native.
library;

export 'video_source_stub.dart'
    if (dart.library.js_interop) 'video_source_web.dart'
    if (dart.library.io) 'video_source_io.dart';
