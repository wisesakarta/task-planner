import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Runs before every test file. `flutter test` does not load the app's fonts
/// on its own: without this, text is drawn in the square test font, so
/// widths, wrapping and overflow checks measure the wrong glyphs.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final interTight = FontLoader('InterTight');
  for (final weight in ['Regular', 'Medium', 'Bold', 'ExtraBold']) {
    interTight.addFont(
      rootBundle.load('assets/fonts/inter_tight/InterTight-$weight.ttf'),
    );
  }
  await interTight.load();
  await testMain();
}
