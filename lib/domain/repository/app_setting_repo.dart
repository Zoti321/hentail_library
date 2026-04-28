import '../../model/models.dart' show AppSetting;

abstract class AppSettingRepository {
  Future<AppSetting> load();

  Future<void> save(AppSetting setting);
}
