/// home 模块 public API（ADR-0034）：跨 feature 经 `public/di/` 直连，避免与 library_admin public 成环。
library;

export 'public/di/home_library_stats_stream.dart';
export 'public/di/home_page_repository_factory.dart';
export 'public/di/home_page_providers.dart';
export 'public/home_cross_feature_types.dart';
export 'public/ui/home_page.dart';
