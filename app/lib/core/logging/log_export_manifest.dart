import 'dart:io';

import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';

Map<String, Object?> buildDiagnosticsManifest({
  required PackageInfo packageInfo,
  required bool diagnosticVerbose,
  bool debugMode = _isDartDebugMode,
}) {
  final String dartLogLevel = Logger.root.level.name;
  final String rustLogLevel = _rustLogLevelLabel(
    diagnosticVerbose,
    debugMode: debugMode,
  );

  return <String, Object?>{
    'app_version': packageInfo.version,
    'build_number': packageInfo.buildNumber,
    'platform': Platform.operatingSystem,
    'os_version': Platform.operatingSystemVersion,
    'exported_at': DateTime.now().toUtc().toIso8601String(),
    'dart_log_level': dartLogLevel,
    'rust_log_level': rustLogLevel,
    'diagnostic_verbose': diagnosticVerbose,
    'debug_mode': debugMode,
  };
}

const bool _isDartDebugMode = !bool.fromEnvironment('dart.vm.product');

String _rustLogLevelLabel(
  bool diagnosticVerbose, {
  required bool debugMode,
}) {
  if (diagnosticVerbose) {
    return 'debug';
  }
  return debugMode ? 'debug' : 'info';
}
