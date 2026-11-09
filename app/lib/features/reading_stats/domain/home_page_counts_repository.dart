import 'package:hentai_library/shared/domain/library/home_page_counts.dart';

/// Home page counts 仓储契约（owner：`reading_stats`）。
abstract class HomePageCountsRepository {
  Stream<HomePageCounts> watchHomePageCounts({required bool excludeR18});
}
