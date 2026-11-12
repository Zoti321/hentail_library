/// series feature public API（ADR-0034 / ADR-0036 / #488）。
///
/// 跨模块只经本 barrel 或 `public/**`；壳（library_browse）单向 watch owner。
library;

export 'public/di/series_item_membership_query_factory.dart';
export 'public/di/series_cover_invalidation_slot_factory.dart';
export 'public/di/series_cover_providers.dart';
export 'public/di/persist_series_item_sort_command_factory.dart';
export 'public/di/series_reading_context_query_factory.dart';
export 'public/di/series_repository_factory.dart';
export 'public/library_age_restriction_series.dart';
export 'public/library_series_browse_rules.dart';
export 'public/series_item_sort_persist.dart';
export 'public/series_comic_page_item.dart';
export 'public/ui/series_cover_content.dart';
export 'public/ui/series_detail_page.dart';
export 'public/ui/series_detail_view_object.dart';
export 'public/ui/series_metadata_edit_draft.dart';
export 'public/ui/series_metadata_edit_mappers.dart';
export 'public/ui/series_metadata_edit_present.dart';
export 'public/ui/series_metadata_edit_presenters.dart';
export 'public/serialization_status.dart';
