import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/app_settings/domain/app_setting.dart';
import 'package:hentai_library/features/app_settings/domain/reading_preferences_schema.dart';
import 'package:hentai_library/features/app_settings/presentation/view_models/settings_notifier.dart';
import 'package:hentai_library/features/app_settings/public/providers/app_settings_providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;

import '../../../support/fakes/settings_test_fakes.dart';

void main() {
  test('AppSetting defaults autoPlayModeId to comicOnce', () {
    expect(
      AppSetting().autoPlayModeId,
      ReadingPreferenceSchema.defaultAutoPlayModeId,
    );
    expect(
      ReadingPreferenceSchema.defaultAutoPlayModeId,
      ReadingPreferenceSchema.autoPlayComicOnceId,
    );
  });

  test('autoPlayModeId round-trips through fromJson/toJson', () {
    final AppSetting setting = AppSetting(
      autoPlayModeId: ReadingPreferenceSchema.autoPlaySeriesLoopId,
    );
    final AppSetting restored = AppSetting.fromJson(setting.toJson());
    expect(
      restored.autoPlayModeId,
      ReadingPreferenceSchema.autoPlaySeriesLoopId,
    );
  });

  test(
    'retains unknown autoPlayMode json verbatim (ACL decode falls back)',
    () {
      final AppSetting setting = AppSetting.fromJson(<String, Object?>{
        'version': 3,
        'autoPlayMode': 'not-a-mode',
      });
      expect(setting.autoPlayModeId, 'not-a-mode');
    },
  );

  test('setAutoPlayModeId persists and reloads', () async {
    final MemoryAppSettingRepository repo = MemoryAppSettingRepository();
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
        .setAutoPlayModeId(ReadingPreferenceSchema.autoPlaySeriesOnceId);

    final ProviderContainer reloaded = create();
    addTearDown(reloaded.dispose);

    final AppSetting loaded = await reloaded.read(settingsProvider.future);
    expect(loaded.autoPlayModeId, ReadingPreferenceSchema.autoPlaySeriesOnceId);
  });
}
