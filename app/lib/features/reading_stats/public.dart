/// reading_stats 模块 public API（ADR-0034）。
///
/// Home page counts / Reading activity stats 由本模块生产；Port 与 token 的
/// 真源也在本模块（ADR-0045「生产者拥有」）。
library;

export 'package:hentai_library/features/reading_stats/domain/home_page_counts.dart';
export 'package:hentai_library/features/reading_stats/domain/home_page_counts_port.dart';
export 'package:hentai_library/features/reading_stats/domain/reading_activity_stats.dart';
export 'package:hentai_library/features/reading_stats/domain/reading_activity_stats_port.dart';
export 'package:hentai_library/features/reading_stats/domain/record_read_session_activity_port.dart';

export 'public/di/home_page_counts_port_factory.dart';
export 'public/di/reading_activity_stats_port_factory.dart';
export 'public/di/reading_stats_providers.dart';
export 'public/di/record_read_session_activity_port_factory.dart';
