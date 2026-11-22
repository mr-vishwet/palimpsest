import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

/// Opens the archive database on the web: real SQLite compiled to
/// WebAssembly, running in a worker, persisted to IndexedDB/OPFS
/// (whichever the browser supports — Drift probes and picks).
/// `sqlite3.wasm` and `drift_worker.js` live in `web/` next to
/// `index.html` (see the drift release notes for the matching files).
QueryExecutor openDbConnection() {
  return LazyDatabase(() async {
    final result = await WasmDatabase.open(
      databaseName: 'palimpsest_archive',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
    );
    return result.resolvedExecutor;
  });
}
