import 'package:hentai_library/src/rust/api/logging.dart';

/// FRB 诊断日志开关（原 `features/app_settings/infrastructure/adapters/`）；core 不得依赖 feature。
void setDiagnosticLoggingFrbAdapter({required bool verbose}) {
  setDiagnosticLoggingFrb(verbose: verbose);
}
