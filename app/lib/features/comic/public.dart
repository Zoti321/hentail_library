/// comic feature public API（ADR-0034 / ADR-0036 / #488）。
///
/// 跨模块只经本 barrel 或 `public/**`；壳（library_browse）单向 watch owner。
library;

export 'public/comic.dart';
export 'public/comic_return_series_commands.dart';
export 'public/comic_display_title.dart';
export 'public/comic_lookup_repository.dart';
export 'public/di/comic_browse_repository_factory.dart';
export 'public/di/comic_cover_providers.dart';
export 'public/di/comic_cover_service.dart';
export 'public/di/comic_detail_providers.dart';
export 'public/di/comic_read_query.dart';
export 'public/di/comic_detail_return_series_factory.dart';
export 'public/di/comic_repository_providers.dart';
export 'public/di/comic_thumbnail_repository_factory.dart';
export 'public/library_comic_browse_rules.dart';
export 'public/library_age_restriction_comic.dart';
export 'public/data/comic_entity_mapper.dart';
export 'public/ui/bulk_edit_metadata_presenter.dart';
export 'public/ui/comic_card_actions.dart';
export 'public/ui/comic_card_host.dart';
export 'public/ui/comic_cover_content.dart';
export 'public/ui/comic_detail_back_location.dart';
export 'public/ui/comic_detail_page.dart';
export 'public/ui/comic_metadata_edit_draft.dart';
export 'public/ui/comic_metadata_edit_mappers.dart';
export 'public/ui/comic_metadata_edit_present.dart';
export 'public/ui/comic_metadata_edit_presenters.dart';
export 'public/comic_metadata_types.dart';
