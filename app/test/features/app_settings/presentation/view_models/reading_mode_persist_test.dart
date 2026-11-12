import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/app_settings/domain/app_setting.dart';
import 'package:hentai_library/features/app_settings/domain/reading_preferences_schema.dart';
import 'package:hentai_library/features/app_settings/presentation/view_models/settings_notifier.dart';
import 'package:hentai_library/features/app_settings/public/di/app_settings_providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;

import '../../../../support/fakes/settings_test_fakes.dart';

void main() {
  test('setReadingModeId persists and reloads as webtoon', () async {
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
        .setReadingModeId(ReadingPreferenceSchema.readingModeWebtoonId);

    final ProviderContainer reloaded = create();
    addTearDown(reloaded.dispose);

    final AppSetting loaded = await reloaded.read(settingsProvider.future);
    expect(loaded.readingModeId, ReadingPreferenceSchema.readingModeWebtoonId);
  });
}
