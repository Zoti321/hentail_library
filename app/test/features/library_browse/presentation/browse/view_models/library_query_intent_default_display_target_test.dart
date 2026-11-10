import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/app_settings/public.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_query_intent_notifier.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;

import '../../../../../support/settings_state_bridge.dart';

class _FixedSettingsNotifier extends SettingsNotifier {
  _FixedSettingsNotifier(this._initial);

  AppSetting _initial;

  @override
  Future<AppSetting> build() async => _initial;

  @override
  Future<void> updateSettings(AppSetting newSetting) async {
    _initial = newSetting;
    state = AsyncData<AppSetting>(newSetting);
  }
}

void main() {
  test('LibraryQueryIntent seeds displayTarget from Default library display target', () async {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        settingsStateBridge(),
        settingsProvider.overrideWith(
          () => _FixedSettingsNotifier(
            AppSetting(
              defaultLibraryDisplayTarget: LibraryDisplayTarget.series,
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(settingsProvider.future);

    expect(
      container.read(libraryQueryIntentProvider).displayTarget,
      LibraryDisplayTarget.series,
    );
  });

  test(
    'changing Default library display target updates the current displayTarget',
    () async {
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          settingsStateBridge(),
          settingsProvider.overrideWith(
            () => _FixedSettingsNotifier(AppSetting()),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(settingsProvider.future);
      container.read(libraryQueryIntentProvider);

      await container
          .read(settingsProvider.notifier)
          .setDefaultLibraryDisplayTarget(LibraryDisplayTarget.series);
      await container.pump();

      expect(
        container.read(libraryQueryIntentProvider).displayTarget,
        LibraryDisplayTarget.series,
      );
    },
  );

  test('resetFilter restores Default library display target', () async {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        settingsStateBridge(),
        settingsProvider.overrideWith(
          () => _FixedSettingsNotifier(
            AppSetting(
              defaultLibraryDisplayTarget: LibraryDisplayTarget.series,
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(settingsProvider.future);

    final LibraryQueryIntentNotifier intent = container.read(
      libraryQueryIntentProvider.notifier,
    );
    intent.setDisplayTarget(LibraryDisplayTarget.comics);
    intent.resetFilter();

    expect(
      container.read(libraryQueryIntentProvider).displayTarget,
      LibraryDisplayTarget.series,
    );
    expect(container.read(libraryQueryIntentProvider).keyword, isEmpty);
  });
}
