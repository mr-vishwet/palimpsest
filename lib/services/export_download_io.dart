import 'dart:io';
import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

/// Delivers [bytes] on native platforms via the system share sheet:
/// the bytes are written to a temp file, shared, and the temp file is
/// removed afterwards.
Future<void> downloadFile(
  Uint8List bytes,
  String fileName,
  String mimeType,
) async {
  final tempDir = await Directory.systemTemp.createTemp('palimpsest-export-');
  final file = File('${tempDir.path}/$fileName');
  try {
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(files: <XFile>[XFile(file.path, mimeType: mimeType)]),
    );
  } finally {
    try {
      await file.delete();
      await tempDir.delete();
    } on FileSystemException {
      // Best effort: a leftover temp file is harmless.
    }
  }
}
