import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import 'export_download.dart' as download;

/// Builds and delivers a story export: a deterministic .zip holding
/// the manifest plus the real media bytes.
///
/// The zip is the export: `manifest.json` at the top plus one entry
/// per media file under `media/`. Every entry carries a fixed
/// timestamp and entries are sorted by name, so re-exporting the same
/// archive produces identical bytes (the deterministic-manifest
/// property, extended to the whole package).
///
/// Delivery is a browser download on web and the system share sheet
/// on native (see [export_download.dart]).
abstract final class ExportDelivery {
  /// The manifest file name inside the zip.
  static const String manifestName = 'manifest.json';

  /// Fixed timestamp written into every zip entry. The ZIP format
  /// stores DOS local time, so bytes are identical on re-export from
  /// the same machine; the epoch date keeps the choice obvious.
  static final DateTime zipEpoch = DateTime.utc(1980, 1, 1);

  /// Builds the zip bytes: the manifest plus [mediaFiles], keyed by
  /// their path inside the zip (e.g. `media/frame-042.jpg`).
  ///
  /// Entries are sorted by path and all carry [zipEpoch], so the
  /// output depends only on the inputs.
  static Uint8List buildZip({
    required String manifest,
    required Map<String, Uint8List> mediaFiles,
  }) {
    final archive = Archive();
    final manifestBytes = Uint8List.fromList(utf8.encode(manifest));
    archive.addFile(
      ArchiveFile(manifestName, manifestBytes.length, manifestBytes),
    );
    final names = mediaFiles.keys.toList(growable: false)..sort();
    for (final name in names) {
      final bytes = mediaFiles[name]!;
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    }
    return ZipEncoder().encodeBytes(archive, modified: zipEpoch);
  }

  /// Delivers the finished zip to the user: a browser download on
  /// web, the system share sheet on native.
  static Future<void> deliverZip(Uint8List zipBytes, String fileName) =>
      download.downloadFile(zipBytes, fileName, 'application/zip');

  /// Picks a file extension for a media MIME type, e.g. `video/mp4`
  /// → `.mp4`. Unknown or missing types get no extension rather than
  /// a guessed one — the bytes are what matter.
  static String extensionForMimeType(String? mimeType) {
    switch (mimeType) {
      case 'image/jpeg':
        return '.jpg';
      case 'image/png':
        return '.png';
      case 'image/gif':
        return '.gif';
      case 'image/webp':
        return '.webp';
      case 'image/heic':
        return '.heic';
      case 'image/heif':
        return '.heif';
      case 'video/mp4':
        return '.mp4';
      case 'video/quicktime':
        return '.mov';
      case 'video/webm':
        return '.webm';
      case 'video/x-matroska':
        return '.mkv';
      case 'audio/wav':
      case 'audio/x-wav':
      case 'audio/vnd.wave':
        return '.wav';
      case 'audio/mpeg':
        return '.mp3';
      case 'audio/mp4':
      case 'audio/aac':
        return '.m4a';
      case 'audio/ogg':
      case 'audio/opus':
        return '.opus';
      case 'audio/flac':
      case 'audio/x-flac':
        return '.flac';
      default:
        return '';
    }
  }
}
