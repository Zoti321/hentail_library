/// reading_history 模块 public API（ADR-0034）。
///
/// Repository 契约经 [shared/di] token + bootstrap 注入；不在 public export。
library;

export 'domain/reading_history.dart';
export 'presentation/models/history_card_item.dart';
export 'presentation/widgets/reading_history_card.dart';
