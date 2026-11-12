import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/app_settings/application/diagnostics/diagnostic_commands.dart';
import 'package:hentai_library/shared/presentation/providers/required_provider.dart';

final Provider<DiagnosticLoggingCommand> diagnosticLoggingCommandProvider =
    requiredProvider('diagnosticLoggingCommandProvider');

final Provider<ExportLogsCommand> exportLogsCommandProvider = requiredProvider(
  'exportLogsCommandProvider',
);
