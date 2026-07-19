import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/models/app_setting.dart';
import 'package:hentai_library/domain/repositories/app_setting_repository.dart';
import 'package:hentai_library/ui/features/settings/view_models/settings_notifier.dart';
import 'package:hentai_library/ui/features/shell/di/repos.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;

void main() {
  test('setLocalePreference persists and reloads as English', () async {
    final _MemoryAppSettingRepository repo = _MemoryAppSettingRepository();
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        appSettingRepoProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);

    await container.read(settingsProvider.future);
    await container
        .read(settingsProvider.notifier)
        .setLocalePreference(AppLocalePreference.en);

    final ProviderContainer reloaded = ProviderContainer(
      overrides: <Override>[
        appSettingRepoProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(reloaded.dispose);

    final AppSetting loaded = await reloaded.read(settingsProvider.future);
    expect(loaded.localePreference, AppLocalePreference.en);
  });
}

class _MemoryAppSettingRepository implements AppSettingRepository {
  AppSetting _setting = AppSetting();

  @override
  Future<AppSetting> load() async => _setting;

  @override
  Future<void> save(AppSetting setting) async {
    _setting = setting;
  }
}
