import 'package:drift/drift.dart';

/// No database connection for this platform (neither web nor dart:io).
QueryExecutor openDbConnection() => throw UnsupportedError(
      'No database connection implementation for this platform',
    );
