import 'package:hentai_library/features/app_settings/presentation/providers/diagnostic_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'diagnostic_mode_notifier.g.dart';

/// 详细诊断开关：仅内存状态，冷启动自动恢复为关闭（ADR-0004）。
@Riverpod(keepAlive: true)
class DiagnosticModeNotifier extends _$DiagnosticModeNotifier {
  @override
  bool build() => false;

  void setEnabled(bool enabled) {
    if (state == enabled) {
      return;
    }
    state = enabled;
    ref.read(diagnosticLoggingCommandProvider)(enabled);
  }

  void disable() => setEnabled(false);
}
