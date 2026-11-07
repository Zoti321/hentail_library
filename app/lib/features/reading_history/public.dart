/// reading_history 模块 public API（ADR-0034）。
///
/// Repository 实现经 [shared/di] token + bootstrap 注入；跨 feature 类型用本 barrel。
library;

export 'domain/reading_history.dart';
export 'public/di/reading_history_command_port_factory.dart';
export 'public/di/reading_history_progress_port_factory.dart';
export 'public/di/reading_history_repository_factory.dart';
export 'public/ui/history_page.dart';
export 'presentation/models/history_card_item.dart';
export 'presentation/widgets/reading_history_card.dart';
