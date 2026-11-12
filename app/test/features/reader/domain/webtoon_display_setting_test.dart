import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/app_settings/domain/app_setting.dart';
import 'package:hentai_library/features/app_settings/domain/reading_preferences_schema.dart';
import 'package:hentai_library/features/app_settings/presentation/view_models/settings_notifier.dart';
import 'package:hentai_library/features/app_settings/public/di/app_settings_providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;

import '../../../support/fakes/settings_test_fakes.dart';

void main() {
  group('Scroll layout display settings persistence', () {
    test('missing json keys fall back to schema defaults', () {
      final AppSetting setting = AppSetting.fromJson(<String, dynamic>{});
      expect(
        setting.webtoonMarginPercent,
        ReadingPreferenceSchema.defaultWebtoonMarginPercent,
      );
      expect(
        setting.webtoonZoomModeId,
        ReadingPreferenceSchema.defaultWebtoonZoomModeId,
      );
    });

    test('setWebtoonMarginPercent persists and reloads', () async {
      final MemoryAppSettingRepository repo = MemoryAppSettingRepository(
        roundTripJsonOnSave: true,
      );
      ProviderContainer create() => ProviderContainer(
        overrides: <Override>[
          appSettingRepositoryProvider.overrideWithValue(repo),
        ],
      );

      final ProviderContainer container = create();
      addTearDown(container.dispose);

      await container.read(settingsProvider.future);
      await container
          .read(readingPreferencesControllerProvider)
          .setWebtoonMarginPercent(35);

      final ProviderContainer reloaded = create();
      addTearDown(reloaded.dispose);

      final AppSetting loaded = await reloaded.read(settingsProvider.future);
      expect(loaded.webtoonMarginPercent, 35);
    });

    test('setWebtoonZoomModeId persists and reloads', () async {
      final MemoryAppSettingRepository repo = MemoryAppSettingRepository(
        roundTripJsonOnSave: true,
      );
      ProviderContainer create() => ProviderContainer(
        overrides: <Override>[
          appSettingRepositoryProvider.overrideWithValue(repo),
        ],
      );

      final ProviderContainer container = create();
      addTearDown(container.dispose);

      await container.read(settingsProvider.future);
      await container
          .read(readingPreferencesControllerProvider)
          .setWebtoonZoomModeId(
            ReadingPreferenceSchema.webtoonZoomOriginalSizeId,
          );

      final ProviderContainer reloaded = create();
      addTearDown(reloaded.dispose);

      final AppSetting loaded = await reloaded.read(settingsProvider.future);
      expect(
        loaded.webtoonZoomModeId,
        ReadingPreferenceSchema.webtoonZoomOriginalSizeId,
      );
    });
  });
}
