import 'package:hentai_library/shared/domain/library/home_page_counts.dart';

/// Home page counts 跨 feature 读口。
///
/// Token：[homePageCountsPortProvider]（`shared/di/reading_stats_providers.dart`）。
/// 实现位于 `reading_stats`；由 bootstrap override 注入。
abstract class HomePageCountsPort {
  Stream<HomePageCounts> watchHomePageCounts({required bool excludeR18});
}
