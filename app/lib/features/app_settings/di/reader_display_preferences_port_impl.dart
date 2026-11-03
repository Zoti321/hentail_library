import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/app_settings/domain/app_setting.dart';
import 'package:hentai_library/features/app_settings/domain/reader_display_preferences_port.dart';
import 'package:hentai_library/features/app_settings/domain/reader_session_preference_types.dart';
import 'package:hentai_library/features/app_settings/presentation/view_models/settings_notifier.dart';

class _ReaderDisplayPreferencesFromSetting
    implements ReaderDisplayPreferencesPort {
  _ReaderDisplayPreferencesFromSetting(this._setting);

  final AppSetting _setting;

  @override
  int get webtoonMarginPercent => _setting.webtoonMarginPercent;

  @override
  WebtoonZoomMode get webtoonZoomMode => _setting.webtoonZoomMode;
}

ReaderDisplayPreferencesPort createReaderDisplayPreferencesPort(Ref ref) {
  final AppSetting setting = ref.watch(settingsProvider).value ?? AppSetting();
  return _ReaderDisplayPreferencesFromSetting(setting);
}
