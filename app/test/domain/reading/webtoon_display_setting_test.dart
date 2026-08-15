import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/models/app_setting.dart';
import 'package:hentai_library/domain/reading/reading_mode.dart';
import 'package:hentai_library/domain/repositories/app_setting_repository.dart';
import 'package:hentai_library/ui/features/settings/view_models/settings_notifier.dart';
import 'package:hentai_library/ui/features/shell/di/repos.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;

void main() {
  group('Scroll layout display settings persistence', () {
    test('missing json keys default to 20% margin and fitWidth', () {
      final AppSetting setting = AppSetting.fromJson(<String, dynamic>{});
      expect(setting.webtoonMarginPercent, 20);
      expect(setting.webtoonZoomMode, WebtoonZoomMode.fitWidth);
    });

    test('setWebtoonMarginPercent persists and reloads', () async {
      final _MemoryAppSettingRepository repo = _MemoryAppSettingRepository();
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[appSettingRepoProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await container.read(settingsProvider.future);
      await container
          .read(settingsProvider.notifier)
          .setWebtoonMarginPercent(35);

      final ProviderContainer reloaded = ProviderContainer(
        overrides: <Override>[appSettingRepoProvider.overrideWithValue(repo)],
      );
      addTearDown(reloaded.dispose);

      final AppSetting loaded = await reloaded.read(settingsProvider.future);
      expect(loaded.webtoonMarginPercent, 35);
    });

    test('setWebtoonZoomMode persists and reloads', () async {
      final _MemoryAppSettingRepository repo = _MemoryAppSettingRepository();
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[appSettingRepoProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await container.read(settingsProvider.future);
      await container
          .read(settingsProvider.notifier)
          .setWebtoonZoomMode(WebtoonZoomMode.originalSize);

      final ProviderContainer reloaded = ProviderContainer(
        overrides: <Override>[appSettingRepoProvider.overrideWithValue(repo)],
      );
      addTearDown(reloaded.dispose);

      final AppSetting loaded = await reloaded.read(settingsProvider.future);
      expect(loaded.webtoonZoomMode, WebtoonZoomMode.originalSize);
    });
  });
}

class _MemoryAppSettingRepository implements AppSettingRepository {
  AppSetting _setting = AppSetting();

  @override
  Future<AppSetting> load() async => _setting;

  @override
  Future<void> save(AppSetting setting) async {
    // Simulate disk round-trip so missing codegen/json keys would drop fields.
    _setting = AppSetting.fromJson(setting.toJson());
  }

  @override
  Future<bool?> peekLegacyAutoScan() async => null;
}
