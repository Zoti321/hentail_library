import 'package:flutter/foundation.dart';
import 'package:hentai_library/core/logging/diagnostic_logging.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

void main() {
  test('defaultAppLogLevel follows build mode', () {
    expect(defaultAppLogLevel(), kDebugMode ? Level.FINE : Level.INFO);
  });
}
