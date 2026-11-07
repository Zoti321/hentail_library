import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/features/app_settings/domain/reader_session_preference_types.dart';

/// 设置页阅读模式文案（留在 app_settings，避免 public 图 app_settings↔read_session 成环）。
extension AppSettingsReadingModeL10n on AppLocalizations {
  String readingModeLabel(ReadingMode mode) {
    return switch (mode) {
      ReadingMode.paged => readingModePaged,
      ReadingMode.webtoon => readingModeWebtoon,
      ReadingMode.dualPage => readingModeDualPage,
      ReadingMode.dualPageNoCover => readingModeDualPageNoCover,
    };
  }
}
