import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

/// Runs `integration_test/*.dart` with `flutter drive` so a profile-mode build
/// can be measured. Frame statistics reported by the test are written to
/// `build/integration_response_data.json`.
Future<void> main() {
  return integrationDriver(
    responseDataCallback: (data) async {
      if (data == null) return;
      final file = File('build/integration_response_data.json');
      await file.parent.create(recursive: true);
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(data),
      );
    },
  );
}
