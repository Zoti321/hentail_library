/// home 模块 public API（ADR-0034）：跨 feature 优先用 [shared/di/home_library_stats_providers.dart] 避免与 library_admin public 成环。
library;

export 'public/di/home_library_stats_stream.dart';
export 'public/di/home_page_repository_factory.dart';
export 'public/home_cross_feature_types.dart';
export 'public/presentation/home_bootstrap_exports.dart';
export 'public/ui/home_md3e_page.dart';
