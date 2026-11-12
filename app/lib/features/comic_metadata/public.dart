/// comic_metadata 模块 public API（ADR-0034）。
///
/// - Comic 表单 / Smart facet：优先 `public/comic_metadata_form.dart`
/// - Widgetbook Lab patterns：`public/ui/metadata_lab_patterns.dart`
/// - 生产管理页：`public/ui/metadata_page.dart`
library;

export 'public/di/comic_metadata_dictionary_providers.dart';
export 'public/di/comic_metadata_dictionary_state_providers.dart';
export 'public/di/comic_metadata_repository_factory.dart';
export 'public/di/comic_metadata_repository_providers.dart';
export 'public/comic_metadata_cross_feature_types.dart';
export 'public/comic_metadata_entities.dart';
export 'public/comic_metadata_form_listing.dart';
export 'public/ui/metadata_page.dart';
