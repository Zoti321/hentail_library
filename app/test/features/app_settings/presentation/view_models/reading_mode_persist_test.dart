import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/app_settings/presentation/view_models/settings_notifier.dart';
import 'package:hentai_library/shared/di/data_providers.dart';
import 'package:hentai_library/shared/domain/models/app_setting.dart';
import 'package:hentai_library/shared/domain/reading/reading_mode.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;

import '../../../../support/fakes/settings_test_fakes.dart';

void main() {
  test('setReadingMode persists and reloads as webtoon', () async {
    final MemoryAppSettingRepository repo = MemoryAppSettingRepository();
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[appSettingRepoProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await container.read(settingsProvider.future);
    await container
        .read(settingsProvider.notifier)
        .setReadingMode(ReadingMode.webtoon);

    final ProviderContainer reloaded = ProviderContainer(
      overrides: <Override>[appSettingRepoProvider.overrideWithValue(repo)],
    );
    addTearDown(reloaded.dispose);

    final AppSetting loaded = await reloaded.read(settingsProvider.future);
    expect(loaded.readingMode, ReadingMode.webtoon);
  });
}
