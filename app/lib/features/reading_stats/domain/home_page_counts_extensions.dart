import 'package:hentai_library/features/reading_stats/domain/home_page_counts.dart';

/// Home page counts 读模型领域行为。
extension HomePageCountsDomain on HomePageCounts {
  bool get isCatalogEmpty =>
      comicCount <= 0 && tagCount <= 0 && seriesCount <= 0 && authorCount <= 0;

  int get totalNamedFacetCount => tagCount + authorCount;
}
