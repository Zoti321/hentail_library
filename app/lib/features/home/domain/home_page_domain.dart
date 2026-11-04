import 'package:hentai_library/features/home/domain/home_page_read_models.dart';

extension HomePageCountsDomain on HomePageCounts {
  bool get isCatalogEmpty =>
      comicCount <= 0 &&
      tagCount <= 0 &&
      seriesCount <= 0 &&
      authorCount <= 0;

  int get totalNamedFacetCount => tagCount + authorCount;
}

extension HomeLibraryAlertDomain on HomeLibraryAlert {
  bool matchesDismissKey(String storedKey) => storedKey == dismissKey();

  /// 用户曾 dismiss，但 sync 指纹已变 → 应重新展示。
  bool shouldResurfaceAfterDismiss({
    required String storedDismissKey,
    required String storedFingerprint,
  }) {
    if (storedDismissKey != dismissKey()) {
      return true;
    }
    return storedFingerprint != dismissFingerprint();
  }
}
