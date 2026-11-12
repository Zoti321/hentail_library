import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/app_settings/presentation/view_models/settings_notifier.dart';
import 'package:hentai_library/features/app_settings/domain/app_setting.dart';

import '../../../../support/fakes/settings_test_fakes.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:hentai_library/features/app_settings/public/di/app_settings_providers.dart';

void main() {
  test('setLocalePreference persists and reloads as English', () async {
    final MemoryAppSettingRepository repo = MemoryAppSettingRepository();
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        appSettingRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);

    await container.read(settingsProvider.future);
    await container
        .read(settingsProvider.notifier)
        .setLocalePreference(AppLocalePreference.en);

    final ProviderContainer reloaded = ProviderContainer(
      overrides: <Override>[
        appSettingRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(reloaded.dispose);

    final AppSetting loaded = await reloaded.read(settingsProvider.future);
    expect(loaded.localePreference, AppLocalePreference.en);
  });
}
