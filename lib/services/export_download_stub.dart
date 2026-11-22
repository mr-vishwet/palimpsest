import 'dart:typed_data';

/// Downloads [bytes] as [fileName] on platforms with no delivery
/// mechanism — always unsupported.
Future<void> downloadFile(
  Uint8List bytes,
  String fileName,
  String mimeType,
) =>
    throw UnsupportedError(
      'File download is not supported on this platform.',
    );
