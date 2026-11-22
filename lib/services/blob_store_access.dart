import 'blob_store.dart';

/// Registry for the app-wide [BlobStore] instance.
///
/// The store is created in `main.dart` (Worker A owns the wiring) and
/// registered here before the first frame; screens and media services
/// read it through [current]. Keeping the lookup in one place means
/// media code never constructs its own store — there is exactly one
/// IndexedDB / documents-dir backing, and tests register the
/// in-memory implementation instead.
///
/// [current] is null only before registration: screens treat that as
/// "originals unavailable" and say so, rather than crashing.
abstract final class BlobStoreAccess {
  static BlobStore? _current;

  /// The registered store, or null before `main.dart` registers it.
  static BlobStore? get current => _current;

  /// Registers the app-wide store. Called once at startup.
  static void register(BlobStore store) {
    _current = store;
  }
}
