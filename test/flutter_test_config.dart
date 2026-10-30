import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Runs before every test file. Each test starts with empty in-memory
/// SharedPreferences, so a profile location saved by one test never
/// reaches the next, and saves don't wait on a platform plugin tests lack.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  await testMain();
}
