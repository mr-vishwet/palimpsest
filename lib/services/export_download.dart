/// Platform file delivery for exports: browser download on web, the
/// system share sheet on native.
library;

export 'export_download_stub.dart'
    if (dart.library.js_interop) 'export_download_web.dart'
    if (dart.library.io) 'export_download_io.dart';
