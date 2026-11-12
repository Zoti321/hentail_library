import 'package:flutter/foundation.dart';
import 'package:hentai_library/infrastructure/frb/diagnostic_logging_frb.dart';
import 'package:logging/logging.dart';

Level defaultAppLogLevel() => kDebugMode ? Level.FINE : Level.INFO;

void applyDiagnosticLogging(bool verbose) {
  Logger.root.level = verbose ? Level.FINE : defaultAppLogLevel();
  setDiagnosticLoggingFrbAdapter(verbose: verbose);
}
