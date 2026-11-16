import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// Starts printing log records in debug builds (D-019). A release build
/// attaches no listener, so it prints nothing.
///
/// Only `level: logger: message` is printed. The error object and stack trace
/// of a record are never printed: they can hold file paths, SQL or values.
/// Log messages themselves never contain amounts, notes or dates
/// (STANDARDS section 5, F-007 AC-11).
void listenToLogs({bool debugMode = kDebugMode, void Function(String)? write}) {
  Logger.root.level = debugMode ? Level.ALL : Level.OFF;
  if (!debugMode) return;
  final out = write ?? debugPrint;
  Logger.root.onRecord.listen(
    (record) => out(
      '${record.level.name}: ${record.loggerName}: '
      '${record.message}',
    ),
  );
}
