import 'package:hentai_library/core/l10n/app_localizations.dart';

import 'reading_preference_types.dart';

/// 阅读偏好枚举在 UI 中的本地化文案（由 read_session 拥有，避免 core→feature 依赖）。
extension ReadingPreferenceL10n on AppLocalizations {
  String readerModeCategoryLabel(ReaderModeCategory category) {
    return switch (category) {
      ReaderModeCategory.paged => readingModeCategoryPaged,
      ReaderModeCategory.webtoon => readingModeCategoryWebtoon,
    };
  }

  String autoPlayModeLabel(AutoPlayMode mode) {
    return switch (mode) {
      AutoPlayMode.comicOnce => autoPlayModeComicOnce,
      AutoPlayMode.comicLoop => autoPlayModeComicLoop,
      AutoPlayMode.seriesOnce => autoPlayModeSeriesOnce,
      AutoPlayMode.seriesLoop => autoPlayModeSeriesLoop,
    };
  }

  String pagedLayoutLabel(PagedLayout layout) {
    return switch (layout) {
      PagedLayout.single => readingModePagedSingle,
      PagedLayout.dual => readingModePagedDual,
    };
  }

  String webtoonZoomModeLabel(WebtoonZoomMode mode) {
    return switch (mode) {
      WebtoonZoomMode.fitWidth => readingModeWebtoonFitWidth,
      WebtoonZoomMode.originalSize => readingModeWebtoonOriginalSize,
    };
  }

  String readingModeLabel(ReadingMode mode) {
    return switch (mode) {
      ReadingMode.paged => readingModePaged,
      ReadingMode.webtoon => readingModeWebtoon,
      ReadingMode.dualPage => readingModeDualPage,
    };
  }

  String readerWebtoonMarginLabel(int percent) {
    if (percent == 0) {
      return readerSettingsMarginNone;
    }
    return readerSettingsMarginPercent(percent);
  }
}
