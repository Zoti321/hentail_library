import 'package:hentai_library/features/app_settings/domain/app_setting.dart';
import 'package:hentai_library/shared/ui/theme/app_font.dart';

/// [AppFontPreference] → bundled [AppFontSpec]（Noto 含 SC/JP i18n fallback）。
AppFontSpec appFontSpecFor(AppFontPreference preference) {
  return appFontSpecForId(switch (preference) {
    AppFontPreference.miSans => 'miSans',
    AppFontPreference.notoSans => 'notoSans',
  });
}
