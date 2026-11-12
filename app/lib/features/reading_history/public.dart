/// reading_history 模块 public API（ADR-0034）。
///
/// Repository 实现经 [shared/di] token + bootstrap 注入；跨 feature 类型用本 barrel。
library;

export 'domain/reading_history.dart';
export 'domain/reading_progress_commands.dart';
export 'public/di/reading_progress_commands_factory.dart';
export 'public/di/reading_history_command_providers.dart';
export 'public/di/reading_progress_stream_factory.dart';
export 'public/di/reading_history_repository_factory.dart';
export 'public/di/reading_history_repository_providers.dart';
export 'public/ui/history_page.dart';
export 'presentation/models/history_card_item.dart';
export 'presentation/widgets/reading_history_card.dart';
