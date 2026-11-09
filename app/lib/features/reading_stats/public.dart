/// reading_stats 模块 public API（ADR-0034）。
///
/// Home page counts 经 [shared/di] token + bootstrap 注入；跨 feature 类型用本 barrel。
library;

export 'package:hentai_library/shared/domain/library/home_page_counts.dart';
export 'public/di/home_page_counts_port_factory.dart';
