/// Platform helpers for reading back a finished recording: on web the
/// recorder hands back a blob URL, on native a file path.
library;

export 'voice_bytes_stub.dart'
    if (dart.library.js_interop) 'voice_bytes_web.dart'
    if (dart.library.io) 'voice_bytes_io.dart';
