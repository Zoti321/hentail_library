import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/app_settings/presentation/view_models/settings_notifier.dart';
import 'package:hentai_library/shared/di/data_providers.dart';
import 'package:hentai_library/shared/domain/models/app_setting.dart';
import 'package:hentai_library/shared/domain/reading/reading_mode.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;

import '../../../support/fakes/settings_test_fakes.dart';

void main() {
  group('Scroll layout display settings persistence', () {
    test('missing json keys default to 20% margin and fitWidth', () {
      final AppSetting setting = AppSetting.fromJson(<String, dynamic>{});
      expect(setting.webtoonMarginPercent, 20);
      expect(setting.webtoonZoomMode, WebtoonZoomMode.fitWidth);
    });

    test('setWebtoonMarginPercent persists and reloads', () async {
      final MemoryAppSettingRepository repo = MemoryAppSettingRepository(
        roundTripJsonOnSave: true,
      );
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
      final MemoryAppSettingRepository repo = MemoryAppSettingRepository(
        roundTripJsonOnSave: true,
      );
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
