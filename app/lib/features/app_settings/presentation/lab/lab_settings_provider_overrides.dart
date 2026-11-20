import 'package:hentai_library/features/app_settings/domain/app_setting.dart';
import 'package:hentai_library/features/app_settings/domain/app_setting_repository.dart';
import 'package:hentai_library/features/app_settings/presentation/providers/app_setting_repository_provider.dart';
import 'package:hentai_library/features/app_settings/presentation/providers/installed_app_version_providers.dart';
import 'package:hentai_library/features/app_settings/presentation/view_models/settings_notifier.dart';
import 'package:riverpod/misc.dart' show Override;

/// Widgetbook / Lab overrides for production settings sections (no `test/` import).
List<Override> labSettingsProviderOverrides({
  AppSetting Function()? settingBuilder,
  String version = '0.0.0-lab',
}) {
  final AppSetting initial = settingBuilder?.call() ?? AppSetting();
  final _LabMemoryAppSettingRepository repository =
      _LabMemoryAppSettingRepository(initial: initial);
  return <Override>[
    appSettingRepositoryProvider.overrideWithValue(repository),
    // ignore: riverpod_lint/scoped_providers_should_specify_dependencies
    settingsProvider.overrideWith(SettingsNotifier.new),
    installedAppVersionQueryProvider.overrideWithValue(() async => version),
  ];
}

class _LabMemoryAppSettingRepository implements AppSettingRepository {
  _LabMemoryAppSettingRepository({required AppSetting initial})
    : _setting = initial;

  AppSetting _setting;

  @override
  Future<AppSetting> load() async => _setting;

  @override
  Future<void> save(AppSetting setting) async {
    _setting = setting;
  }

  @override
  Future<bool?> peekLegacyAutoScan() async => null;

  @override
  Future<({Object? enabledFormatGroups})?>
  peekLegacyResourceFormatPayload() async => null;

  @override
  Future<void> clearLegacyImportPayload() async {}
}
