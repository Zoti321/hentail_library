import 'package:hentai_library/features/app_settings/domain/app_setting.dart';

/// 应用设置持久化后的领域事件（供应用层桥接，不含存储细节）。
sealed class AppSettingEvent {
  const AppSettingEvent();
}

final class AppSettingReaderPreferencesChanged extends AppSettingEvent {
  const AppSettingReaderPreferencesChanged(this.snapshot);

  final AppSetting snapshot;
}
