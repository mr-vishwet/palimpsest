import 'dart:typed_data';

import 'package:exif/exif.dart';
import 'package:image/image.dart' as img;

/// Metadata read off an imported file. Every field is best-effort:
/// a file without EXIF, or with EXIF the parser cannot read, yields
/// nulls rather than failing the import.
class MediaMetadata {
  /// Creates metadata.
  const MediaMetadata({
    this.takenAt,
    this.gpsLat,
    this.gpsLng,
    this.widthPx,
    this.heightPx,
    this.orientation,
  });

  /// Empty metadata: nothing could be read.
  static const MediaMetadata empty = MediaMetadata();

  /// Capture time from EXIF DateTimeOriginal, when present.
  final DateTime? takenAt;

  /// GPS latitude from EXIF, when present.
  final double? gpsLat;

  /// GPS longitude from EXIF, when present.
  final double? gpsLng;

  /// Pixel width from the decoded image, when decodable.
  final int? widthPx;

  /// Pixel height from the decoded image, when decodable.
  final int? heightPx;

  /// EXIF orientation (1–8), when present.
  final int? orientation;
}

/// Pure-Dart media helpers for import: EXIF parsing and thumbnail
/// generation. Nothing here touches the platform, so it runs
/// identically on the VM, in Chrome, and on native.
abstract final class MediaMetadataReader {
  /// Reads EXIF + pixel dimensions from image [bytes]. Never throws:
  /// unreadable EXIF or an undecodable image yields
  /// [MediaMetadata.empty] (or partial metadata) instead of failing
  /// the import.
  static Future<MediaMetadata> readImage(Uint8List bytes) async {
    DateTime? takenAt;
    double? gpsLat;
    double? gpsLng;
    int? orientation;
    try {
      final tags = await readExifFromBytes(bytes);
      takenAt = _parseExifDate(
        // Cameras write DateTimeOriginal in the EXIF IFD; some
        // writers (PIL, image tools) put it in IFD0 instead, and
        // older files carry only the IFD0 DateTime tag.
        tags['EXIF DateTimeOriginal']?.printable ??
            tags['Image DateTimeOriginal']?.printable ??
            tags['Image DateTime']?.printable,
      );
      orientation = _parseOrientation(tags['Image Orientation']);
      gpsLat = _parseGps(
        tags['GPS GPSLatitude'],
        tags['GPS GPSLatitudeRef']?.printable,
        positiveRef: 'N',
      );
      gpsLng = _parseGps(
        tags['GPS GPSLongitude'],
        tags['GPS GPSLongitudeRef']?.printable,
        positiveRef: 'E',
      );
    } catch (_) {
      // EXIF is best-effort: a file with corrupt or missing EXIF
      // still imports, with its metadata filled from the filename
      // and the import time instead.
    }
    int? widthPx;
    int? heightPx;
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded != null) {
        widthPx = decoded.width;
        heightPx = decoded.height;
      }
    } catch (_) {
      // Undecodable image (or a video): dimensions stay unknown.
    }
    return MediaMetadata(
      takenAt: takenAt,
      gpsLat: gpsLat,
      gpsLng: gpsLng,
      widthPx: widthPx,
      heightPx: heightPx,
      orientation: orientation,
    );
  }

  /// Builds a JPEG thumbnail of [bytes]: longest side [maxSize] px,
  /// quality 82, EXIF orientation baked in. Returns null when [bytes]
  /// is not a decodable image (videos, unsupported formats) — the
  /// tile falls back to its gradient in that case.
  static Uint8List? makeThumbnail(Uint8List bytes, {int maxSize = 512}) {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        return null;
      }
      final oriented = img.bakeOrientation(decoded);
      final img.Image thumb;
      if (oriented.width <= maxSize && oriented.height <= maxSize) {
        thumb = oriented;
      } else if (oriented.width >= oriented.height) {
        thumb = img.copyResize(oriented, width: maxSize);
      } else {
        thumb = img.copyResize(oriented, height: maxSize);
      }
      return img.encodeJpg(thumb, quality: 82);
    } catch (_) {
      return null;
    }
  }

  /// EXIF dates look like `2024:05:12 14:30:00`.
  static DateTime? _parseExifDate(String? raw) {
    if (raw == null) {
      return null;
    }
    final parts = raw.trim().split(' ');
    if (parts.length != 2) {
      return null;
    }
    final date = parts[0].replaceAll(':', '-');
    return DateTime.tryParse('$date ${parts[1]}');
  }

  static int? _parseOrientation(IfdTag? tag) {
    if (tag == null) {
      return null;
    }
    final values = tag.values.toList();
    if (values.isNotEmpty) {
      final first = values.first;
      if (first is num) {
        return first.toInt();
      }
    }
    return int.tryParse(tag.printable.trim());
  }

  /// GPS is three rationals (degrees, minutes, seconds) plus a
  /// hemisphere ref. South and West negate the value.
  static double? _parseGps(
    IfdTag? tag,
    String? ref, {
    required String positiveRef,
  }) {
    if (tag == null || tag.values.length < 3) {
      return null;
    }
    final values = tag.values.toList();
    final degrees = _asDouble(values[0]);
    final minutes = _asDouble(values[1]);
    final seconds = _asDouble(values[2]);
    if (degrees == null || minutes == null || seconds == null) {
      return null;
    }
    var value = degrees + minutes / 60 + seconds / 3600;
    if (ref != null && ref.trim().toUpperCase() != positiveRef) {
      value = -value;
    }
    return value;
  }

  static double? _asDouble(Object? value) {
    if (value is Ratio) {
      return value.toDouble();
    }
    if (value is num) {
      return value.toDouble();
    }
    return null;
  }
}
