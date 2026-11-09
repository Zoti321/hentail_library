/// series feature public API（ADR-0034 / ADR-0036 / #457）。
///
/// browse 壳集成走 `library_browse` 本地 `series_presentation_bridge`，
/// 不再经本 barrel re-export presentation 壳桶。
library;

export 'public/di/series_cover_providers.dart';
export 'public/di/series_item_sort_port_factory.dart';
export 'public/di/series_reading_context_port_factory.dart';
export 'public/di/series_repository_factory.dart';
export 'public/library_series_browse_rules.dart';
export 'public/series_item_sort_persist.dart';
export 'public/ui/series_cover_content.dart';
export 'public/ui/series_detail_page.dart';
