import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Downloads [bytes] as [fileName] in the browser: the bytes become a
/// Blob, an anchor click starts the download, and the object URL is
/// revoked once the click has been dispatched.
Future<void> downloadFile(
  Uint8List bytes,
  String fileName,
  String mimeType,
) async {
  final blob = web.Blob(
    <web.BlobPart>[bytes.toJS].toJS,
    web.BlobPropertyBag(type: mimeType),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor =
      web.document.createElement('a') as web.HTMLAnchorElement
        ..href = url
        ..download = fileName;
  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
  // Revoke on a microtask so the browser has taken the URL first.
  await Future<void>.delayed(Duration.zero);
  web.URL.revokeObjectURL(url);
}
