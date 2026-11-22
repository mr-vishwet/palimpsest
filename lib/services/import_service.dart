import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../models/memory_item.dart';
import 'blob_store.dart';
import 'media_metadata.dart';

/// One file picked for import: the name the picker reported and the
/// bytes read off the device. The screen builds these from the picker
/// result (web: picked with data, native: read from the picked path);
/// the service never touches the picker, so it stays unit-testable.
class ImportFileInput {
  /// Creates an import input.
  const ImportFileInput({
    required this.name,
    required this.bytes,
    this.folder,
  });

  /// The filename as picked, e.g. `IMG_0421.jpg`.
  final String name;

  /// The file bytes.
  final Uint8List bytes;

  /// The folder the file came from, when the picker knows it (used
  /// for an auto-tag). Null on web, where the picker hides paths.
  final String? folder;
}

/// One file that could not be imported, with the reason shown to the
/// user. A failure never aborts the batch.
class ImportFailure {
  /// Creates an import failure.
  const ImportFailure({required this.name, required this.reason});

  /// The filename that failed.
  final String name;

  /// Why it failed, in user-facing words.
  final String reason;
}

/// The result of an import batch: what landed and what did not.
class ImportResult {
  /// Creates an import result.
  const ImportResult({required this.imported, required this.failures});

  /// Items imported (already stored as blobs; the caller adds them
  /// to the archive).
  final List<MemoryItem> imported;

  /// Files that failed, with reasons.
  final List<ImportFailure> failures;

  /// Files attempted in total.
  int get total => imported.length + failures.length;

  /// True when every file imported.
  bool get allSucceeded => failures.isEmpty;
}

/// Progress callback: [done] files processed out of [total],
/// [currentName] the file being processed now (empty on completion).
typedef ImportProgress = void Function(int done, int total, String currentName);

/// The real import pipeline: file bytes in, archive items out.
///
/// For each file: SHA-256 of the bytes (the provenance checksum),
/// EXIF parse (capture date, GPS, orientation, dimensions), a
/// 512px JPEG thumbnail, original + thumbnail into the blob store,
/// and a [MemoryItem] with starter metadata derived from the file
/// (title from the filename, tags from the folder + year/month).
///
/// Videos import with size + mime + filename only: duration and
/// dimensions are probed on first playback (the video player owns
/// that) and written back onto the item then. Import never blocks
/// on a player.
///
/// A bad file skips with a reason and never aborts the batch.
class ImportService {
  /// Creates an import service over [blobs].
  ImportService({required BlobStore blobs}) : _blobs = blobs;

  final BlobStore _blobs;

  /// Photo extensions the pipeline accepts. HEIC/HEIF/AVIF import
  /// (bytes + metadata) but get no thumbnail until the image decoder
  /// supports them — the tile falls back to its gradient.
  static const Set<String> photoExtensions = <String>{
    'jpg',
    'jpeg',
    'png',
    'webp',
    'gif',
    'bmp',
    'heic',
    'heif',
    'avif',
  };

  /// Video extensions the pipeline accepts.
  static const Set<String> videoExtensions = <String>{
    'mp4',
    'mov',
    'm4v',
    'webm',
    'mkv',
    'avi',
  };

  static const Map<String, String> _mimeTypes = <String, String>{
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
    'gif': 'image/gif',
    'bmp': 'image/bmp',
    'heic': 'image/heic',
    'heif': 'image/heif',
    'avif': 'image/avif',
    'mp4': 'video/mp4',
    'mov': 'video/quicktime',
    'm4v': 'video/x-m4v',
    'webm': 'video/webm',
    'mkv': 'video/x-matroska',
    'avi': 'video/x-msvideo',
  };

  static const List<String> _monthNames = <String>[
    'january',
    'february',
    'march',
    'april',
    'may',
    'june',
    'july',
    'august',
    'september',
    'october',
    'november',
    'december',
  ];

  /// Imports [files] one by one, reporting progress through
  /// [onProgress]. Pass `isDemo: true` for demo-media imports (real
  /// files, labelled demo so the UI can say so).
  Future<ImportResult> importFiles(
    List<ImportFileInput> files, {
    bool isDemo = false,
    ImportProgress? onProgress,
  }) async {
    final imported = <MemoryItem>[];
    final failures = <ImportFailure>[];
    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      onProgress?.call(i, files.length, file.name);
      try {
        final item = await _importOne(file, isDemo: isDemo);
        if (item != null) {
          imported.add(item);
        } else {
          failures.add(
            ImportFailure(
              name: file.name,
              reason: 'Unsupported file type — photos and videos only',
            ),
          );
        }
      } catch (e) {
        failures.add(
          ImportFailure(name: file.name, reason: _describeError(e)),
        );
      }
    }
    onProgress?.call(files.length, files.length, '');
    return ImportResult(imported: imported, failures: failures);
  }

  Future<MemoryItem?> _importOne(
    ImportFileInput file, {
    required bool isDemo,
  }) async {
    final ext = _extension(file.name);
    final kind = _kindFor(ext);
    if (kind == null) {
      return null;
    }
    if (file.bytes.isEmpty) {
      throw const FormatException('Empty file');
    }
    final checksum = sha256.convert(file.bytes).toString();
    final blobId = await _blobs.put(file.bytes);

    String? thumbBlobId;
    var metadata = MediaMetadata.empty;
    var widthPx = 0;
    var heightPx = 0;
    if (kind == MediaKind.photo) {
      metadata = await MediaMetadataReader.readImage(file.bytes);
      final thumb = MediaMetadataReader.makeThumbnail(file.bytes);
      if (thumb != null) {
        thumbBlobId = await _blobs.put(thumb);
      }
      widthPx = metadata.widthPx ?? 0;
      heightPx = metadata.heightPx ?? 0;
    }

    final takenAt = metadata.takenAt ?? DateTime.now();
    final folder = file.folder?.trim();
    final tags = <String>{
      if (folder != null && folder.isNotEmpty) folder.toLowerCase(),
      takenAt.year.toString(),
      _monthNames[takenAt.month - 1],
    }.toList(growable: false);

    return MemoryItem(
      id: 'mem-${checksum.substring(0, 16)}-'
          '${takenAt.millisecondsSinceEpoch}',
      kind: kind,
      title: _titleFromName(file.name),
      takenAt: takenAt,
      checksum: checksum,
      tags: tags,
      aspectRatio: aspectLabelFor(widthPx, heightPx),
      widthPx: widthPx,
      heightPx: heightPx,
      isDemo: isDemo,
      blobId: blobId,
      thumbBlobId: thumbBlobId,
      mimeType: _mimeTypes[ext],
      sourceName: file.name,
      gpsLat: metadata.gpsLat,
      gpsLng: metadata.gpsLng,
    );
  }

  static String _extension(String name) {
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) {
      return '';
    }
    return name.substring(dot + 1).toLowerCase();
  }

  static MediaKind? _kindFor(String ext) {
    if (photoExtensions.contains(ext)) {
      return MediaKind.photo;
    }
    if (videoExtensions.contains(ext)) {
      return MediaKind.video;
    }
    return null;
  }

  static String _titleFromName(String name) {
    final dot = name.lastIndexOf('.');
    final base = dot > 0 ? name.substring(0, dot) : name;
    final clean = base.replaceAll(RegExp(r'[_-]+'), ' ').trim();
    return clean.isEmpty ? 'Untitled' : clean;
  }

  /// Nearest standard aspect label for the pixel dimensions.
  /// Shared with the archive controller so probed video dimensions
  /// update the tile label the same way import does.
  static String aspectLabelFor(int widthPx, int heightPx) {
    if (widthPx <= 0 || heightPx <= 0) {
      return '4:3';
    }
    const labels = <String, double>{
      '1:1': 1.0,
      '4:3': 4 / 3,
      '3:4': 3 / 4,
      '3:2': 3 / 2,
      '2:3': 2 / 3,
      '16:9': 16 / 9,
      '9:16': 9 / 16,
      '1.85:1': 1.85,
      '2.39:1': 2.39,
    };
    final ratio = widthPx / heightPx;
    var best = '4:3';
    var bestDistance = double.infinity;
    for (final entry in labels.entries) {
      final distance = (ratio / entry.value - 1).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        best = entry.key;
      }
    }
    return best;
  }

  static String _describeError(Object error) {
    if (error is FormatException) {
      final message = error.message;
      return message.isEmpty ? 'Could not read this file' : message;
    }
    return 'Could not read this file';
  }
}
