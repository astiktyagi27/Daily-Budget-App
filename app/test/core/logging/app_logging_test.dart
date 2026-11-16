import 'package:daily_budget/core/logging/app_logging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

void main() {
  tearDown(() {
    Logger.root.clearListeners();
    Logger.root.level = Level.INFO;
  });

  test('TC-007-21 debug logging prints level logger and message only', () {
    final lines = <String>[];
    listenToLogs(write: lines.add);
    Logger('database').warning(
      'database open failed: corrupt',
      StateError(r'C:\data\budget.sqlite'),
      StackTrace.current,
    );
    expect(lines, ['WARNING: database: database open failed: corrupt']);
  });

  test('TC-007-21 a release build attaches no log listener', () {
    final lines = <String>[];
    listenToLogs(debugMode: false, write: lines.add);
    Logger('database').severe('database open failed: corrupt');
    expect(lines, isEmpty);
    expect(Logger.root.level, Level.OFF);
  });
}
