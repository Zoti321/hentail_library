import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/bootstrap/di/composition_overrides.dart';
import 'package:hentai_library/features/bootstrap/di/deps.dart';
import 'package:hentai_library/features/bootstrap/di/shared_state_overrides.dart';
import 'package:hentai_library/shared/domain/library/resource_format_category.dart';
import 'package:hentai_library/shared/domain/models/app_setting.dart';
import 'package:hentai_library/shared/domain/repositories/app_setting_repository.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod/misc.dart' show Override;

/// Shared Settings overrides for shell/settings widget tests.
List<Override> settingsViewTestOverrides({
  AppSetting Function()? settingBuilder,
  PackageInfo? packageInfo,
}) {
  return <Override>[
    ...sharedLibraryStateOverrides(),
    ...bootstrapCompositionOverrides(),
    settingsProvider.overrideWith(
      () => FakeSettingsNotifier(settingBuilder: settingBuilder),
    ),
    packageInfoProvider.overrideWith(
      (Ref ref) async =>
          packageInfo ??
          PackageInfo(
            appName: 'Hentai Library',
            packageName: 'hentai_library',
            version: '1.0.0',
            buildNumber: '1',
          ),
    ),
  ];
}

class FakeSettingsNotifier extends SettingsNotifier {
  FakeSettingsNotifier({this._settingBuilder});

  final AppSetting Function()? _settingBuilder;

  @override
  Future<AppSetting> build() async => _settingBuilder?.call() ?? AppSetting();
}

/// In-memory [AppSettingRepository] for unit/widget tests (load/save + legacy peek).
class MemoryAppSettingRepository implements AppSettingRepository {
  MemoryAppSettingRepository({
    AppSetting? initial,
    this.legacyAutoScan,
    this.legacyEnabledResourceFormatCategories,
    this.roundTripJsonOnSave = false,
  }) : _setting = initial ?? AppSetting();

  final bool? legacyAutoScan;
  final List<ResourceFormatCategory>? legacyEnabledResourceFormatCategories;
  final bool roundTripJsonOnSave;

  AppSetting _setting;
  int clearLegacyImportPayloadCalls = 0;

  @override
  Future<AppSetting> load() async => _setting;

  @override
  Future<void> save(AppSetting setting) async {
    _setting = roundTripJsonOnSave
        ? AppSetting.fromJson(setting.toJson())
        : setting;
  }

  @override
  Future<bool?> peekLegacyAutoScan() async => legacyAutoScan;

  @override
  Future<List<ResourceFormatCategory>?> peekLegacyEnabledResourceFormatCategories() async =>
      legacyEnabledResourceFormatCategories;

  @override
  Future<void> clearLegacyImportPayload() async {
    clearLegacyImportPayloadCalls++;
  }
}
