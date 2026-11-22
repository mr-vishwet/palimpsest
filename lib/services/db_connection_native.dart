import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

/// Opens the archive database natively: a SQLite file in the app
/// documents directory.
QueryExecutor openDbConnection() {
  return LazyDatabase(() async {
    final docs = await getApplicationDocumentsDirectory();
    final file = File('${docs.path}/palimpsest_archive.sqlite');
    return NativeDatabase.createInBackground(file);
  });
}
