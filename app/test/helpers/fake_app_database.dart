import 'package:daily_budget/data/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stands in for the opened database in widget tests (look-ahead #5: widget
/// tests never touch Drift). Any use throws, so a test that reaches for the
/// database instead of a fake repository fails loudly.
class FakeAppDatabase extends Fake implements AppDatabase;
