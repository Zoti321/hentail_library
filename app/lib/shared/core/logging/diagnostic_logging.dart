import 'package:flutter/foundation.dart';
import 'package:hentai_library/shared/data/adapters/diagnostic_logging_frb_adapter.dart';
import 'package:logging/logging.dart';

Level defaultAppLogLevel() => kDebugMode ? Level.FINE : Level.INFO;

void applyDiagnosticLogging(bool verbose) {
  Logger.root.level = verbose ? Level.FINE : defaultAppLogLevel();
  setDiagnosticLoggingFrbAdapter(verbose: verbose);
}
