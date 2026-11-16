typedef DiagnosticLoggingCommand = void Function(bool verbose);

typedef ExportLogsCommand = Future<void> Function({
  required String outputPath,
  required bool redact,
  required bool diagnosticVerbose,
});
