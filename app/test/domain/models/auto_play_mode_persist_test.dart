import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/models/app_setting.dart';
import 'package:hentai_library/domain/reading/auto_play_mode.dart';
import 'package:hentai_library/domain/repositories/app_setting_repository.dart';
import 'package:hentai_library/ui/features/settings/view_models/settings_notifier.dart';
import 'package:hentai_library/ui/features/shell/di/repos.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;

void main() {
  test('AppSetting defaults autoPlayMode to comicOnce', () {
    expect(AppSetting().autoPlayMode, AutoPlayMode.comicOnce);
    expect(kDefaultAutoPlayMode, AutoPlayMode.comicOnce);
  });

  test('autoPlayMode round-trips through fromJson/toJson', () {
    final AppSetting setting = AppSetting(
      autoPlayMode: AutoPlayMode.seriesLoop,
    );
    final AppSetting restored = AppSetting.fromJson(setting.toJson());
    expect(restored.autoPlayMode, AutoPlayMode.seriesLoop);
  });

  test('unknown autoPlayMode json falls back to comicOnce', () {
    final AppSetting setting = AppSetting.fromJson(<String, Object?>{
      'version': 3,
      'autoPlayMode': 'not-a-mode',
    });
    expect(setting.autoPlayMode, AutoPlayMode.comicOnce);
  });

  test('setAutoPlayMode persists and reloads', () async {
    final _MemoryAppSettingRepository repo = _MemoryAppSettingRepository();
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[appSettingRepoProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await container.read(settingsProvider.future);
    await container
        .read(settingsProvider.notifier)
        .setAutoPlayMode(AutoPlayMode.seriesOnce);

    final ProviderContainer reloaded = ProviderContainer(
      overrides: <Override>[appSettingRepoProvider.overrideWithValue(repo)],
    );
    addTearDown(reloaded.dispose);

    final AppSetting loaded = await reloaded.read(settingsProvider.future);
    expect(loaded.autoPlayMode, AutoPlayMode.seriesOnce);
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

  @override
  Future<bool?> peekLegacyAutoScan() async => null;
}
