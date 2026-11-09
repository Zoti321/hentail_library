import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/di/injected_di.dart';
import 'package:hentai_library/features/app_settings/domain/app_setting.dart';
import 'package:hentai_library/features/app_settings/domain/app_theme_preferences_port.dart';
import 'package:hentai_library/features/app_settings/domain/reader_display_preferences_port.dart';
import 'package:hentai_library/features/app_settings/domain/reader_settings_command_port.dart';

/// 应用设置的共享状态与端口 Provider 声明（#265 / ADR-0034 #426）。
///
/// 只声明、不实现；默认抛 [UnimplementedError]，由 bootstrap 注入 app_settings 的实现。

/// 应用设置（同步可读形态）。
final Provider<AsyncValue<AppSetting>> appSettingsStateProvider = injectedDi(
  'appSettingsStateProvider',
);

/// 应用设置（等待首次加载完成的 Future 形态）。
final FutureProvider<AppSetting> appSettingsFutureProvider = injectedFutureDi(
  'appSettingsFutureProvider',
);

/// 阅读器设置写入端口。
final Provider<ReaderSettingsCommandPort> readerSettingsCommandPortProvider =
    injectedDi('readerSettingsCommandPortProvider');

/// 主题偏好只读端口（shell / theme 将来读取；动态色本迭代 no-op）。
final Provider<AppThemePreferencesPort> appThemePreferencesPortProvider =
    injectedDi('appThemePreferencesPortProvider');

/// 阅读器展示偏好（webtoon 边距/缩放等）。
final Provider<ReaderDisplayPreferencesPort>
readerDisplayPreferencesPortProvider = injectedDi(
  'readerDisplayPreferencesPortProvider',
);
