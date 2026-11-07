/// comic feature public API（ADR-0034 / ADR-0036 / #457）。
///
/// browse 壳集成走 `library_browse` 本地 `comic_presentation_bridge`，
/// 不再经本 barrel re-export presentation 壳桶。
library;

export 'public/comic_detail_return_series_port.dart';
export 'public/comic_display_title.dart';
export 'public/comic_lookup_repository.dart';
export 'public/di/comic_browse_repository_factory.dart';
export 'public/di/comic_cover_providers.dart';
export 'public/di/comic_detail_return_series_factory.dart';
export 'public/di/comic_repository_providers.dart';
export 'public/di/comic_thumbnail_repository_factory.dart';
export 'public/library_comic_browse_rules.dart';
export 'public/comic_detail_return_series.dart';
export 'public/ui/comic_detail_layout.dart';
export 'public/smart_facet_match_preference.dart';
export 'public/ui/comic_cover_content.dart';
export 'public/ui/comic_detail_page.dart';
