import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/archive_data.dart';

/// Local-first persistence for the whole archive.
///
/// v0.1 stores the archive as one versioned JSON document under a
/// single key. The interface is deliberately narrow (`load` / `save` /
/// `clear`) so a Drift/SQLite store can replace this implementation
/// behind the same interface in phase 2 without changing any caller.
class ArchiveStore {
  /// Storage key for the versioned archive document.
  static const String storageKey = 'palimpsest_archive_v1';

  /// Loads the stored archive, or null on a first run (or when the
  /// stored document cannot be parsed — v0.1 reseeds in that case;
  /// a real migration path is a phase-2 item).
  Future<ArchiveData?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null) {
      return null;
    }
    try {
      final json = jsonDecode(raw) as Map<String, Object?>;
      return ArchiveData.fromJson(json);
    } on FormatException {
      return null;
    } on TypeError {
      // Syntactically valid JSON with the wrong shape (a stale or
      // corrupted document): the `as` casts in fromJson throw
      // TypeError, and main() awaits load() before the first frame,
      // so an uncaught throw here is a blank screen with no
      // recovery. Reseed instead, as the doc comment promises.
      return null;
    } on ArgumentError {
      // Same: an unknown enum name (e.g. ImportStatus.byName) in a
      // stale document must reseed, not crash the launch.
      return null;
    }
  }

  /// Persists the whole archive document.
  Future<void> save(ArchiveData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, jsonEncode(data.toJson()));
  }

  /// Removes the stored archive (used by "delete local archive").
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
  }
}
