import 'package:hentai_library/features/home/domain/home_page_read_models.dart';

/// 首页仪表盘统计（读模型）领域行为。
extension HomePageCountsDomain on HomePageCounts {
  bool get isCatalogEmpty =>
      comicCount <= 0 &&
      tagCount <= 0 &&
      seriesCount <= 0 &&
      authorCount <= 0;

  int get totalNamedFacetCount => tagCount + authorCount;
}

/// 首页库告警 dismiss 规约。
abstract final class HomeLibraryAlertDismissSpecification {
  HomeLibraryAlertDismissSpecification._();

  static bool shouldResurfaceAfterDismiss({
    required HomeLibraryAlert alert,
    required String storedDismissKey,
    required String storedFingerprint,
  }) {
    if (storedDismissKey != alert.dismissKey()) {
      return true;
    }
    return storedFingerprint != alert.dismissFingerprint();
  }
}

extension HomeLibraryAlertDomain on HomeLibraryAlert {
  bool matchesDismissKey(String storedKey) => storedKey == dismissKey();
}
