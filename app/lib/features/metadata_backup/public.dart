/// metadata_backup 模块 public API（ADR-0034）。
///
/// Bootstrap 槽位注入与跨 feature 类型经本 barrel；实现细节留在 feature 内。
library;

export 'data/services/recent_metadata_backup_at.dart';
export 'domain/metadata_export_options.dart';
export 'presentation/metadata_export_flow.dart';
export 'presentation/view_models/metadata_auto_backup_coordinator_notifier.dart';
export 'presentation/views/metadata_backup_settings_sections.dart';
