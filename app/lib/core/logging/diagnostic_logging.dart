import 'package:flutter/foundation.dart';
import 'package:hentai_library/src/rust/api/logging.dart';
import 'package:logging/logging.dart';

Level defaultAppLogLevel() => kDebugMode ? Level.FINE : Level.INFO;

void applyDiagnosticLogging(bool verbose) {
  Logger.root.level = verbose ? Level.FINE : defaultAppLogLevel();
  setDiagnosticLoggingFrb(verbose: verbose);
}
