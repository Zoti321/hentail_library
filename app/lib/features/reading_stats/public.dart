/// reading_stats 模块 public API（ADR-0034）。
///
/// Home page counts / Reading activity stats 经 [shared/di] token + bootstrap 注入。
library;

export 'package:hentai_library/shared/domain/library/home_page_counts.dart';
export 'package:hentai_library/shared/domain/library/reading_activity_stats.dart';
export 'public/di/home_page_counts_port_factory.dart';
export 'public/di/reading_activity_stats_port_factory.dart';
