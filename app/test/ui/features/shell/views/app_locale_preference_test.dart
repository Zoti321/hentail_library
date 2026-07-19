import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/models/app_setting.dart';
import 'package:hentai_library/ui/features/settings/state/app_update_coordinator_notifier.dart';
import 'package:hentai_library/ui/features/settings/view_models/settings_notifier.dart';
import 'package:hentai_library/ui/features/shell/state/app_startup_coordinator_notifier.dart';
import 'package:hentai_library/ui/features/shell/views/app.dart';
import 'package:hentai_library/ui/providers/comic_cover_providers.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:riverpod/riverpod.dart' show AsyncData;

void main() {
  testWidgets(
    'en locale preference sets MaterialApp.locale to en',
    (WidgetTester tester) async {
      final MaterialApp app = await _pumpApp(
        tester,
        AppSetting(localePreference: AppLocalePreference.en),
      );
      expect(app.locale, const Locale('en'));
    },
  );

  testWidgets(
    'zhCn locale preference sets MaterialApp.locale to zh',
    (WidgetTester tester) async {
      final MaterialApp app = await _pumpApp(
        tester,
        AppSetting(localePreference: AppLocalePreference.zhCn),
      );
      expect(app.locale, const Locale('zh'));
    },
  );

  testWidgets(
    'system locale preference leaves MaterialApp.locale null',
    (WidgetTester tester) async {
      final MaterialApp app = await _pumpApp(
        tester,
        AppSetting(localePreference: AppLocalePreference.system),
      );
      expect(app.locale, isNull);
    },
  );
}

Future<MaterialApp> _pumpApp(WidgetTester tester, AppSetting setting) async {
  tester.view.physicalSize = const Size(1200, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(MyApp(overrides: _overrides(setting)));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));

  return tester.widget(find.byType(MaterialApp));
  testWidgets(
    'setLocalePreference refreshes MaterialApp.locale without rebuild',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final _MutableSettingsNotifier settings = _MutableSettingsNotifier(
        AppSetting(localePreference: AppLocalePreference.zhCn),
      );

      await tester.pumpWidget(
        MyApp(
          overrides: <Override>[
            thumbnailEventCoordinatorProvider.overrideWith(
              _FakeThumbnailEventCoordinator.new,
            ),
            settingsProvider.overrideWith(() => settings),
            appUpdateCoordinatorProvider.overrideWith(
              _FakeAppUpdateCoordinator.new,
            ),
            appStartupCoordinatorProvider.overrideWith(
              _FakeAppStartupCoordinator.new,
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).locale,
        const Locale('zh'),
      );

      await settings.setLocalePreference(AppLocalePreference.en);
      await tester.pump();

      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).locale,
        const Locale('en'),
      );
    },
  );
}

List<Override> _overrides(AppSetting setting) {
  return <Override>[
    thumbnailEventCoordinatorProvider.overrideWith(
      _FakeThumbnailEventCoordinator.new,
    ),
    settingsProvider.overrideWith(() => _FakeSettingsNotifier(setting)),
    appUpdateCoordinatorProvider.overrideWith(_FakeAppUpdateCoordinator.new),
    appStartupCoordinatorProvider.overrideWith(_FakeAppStartupCoordinator.new),
  ];
}

class _FakeThumbnailEventCoordinator extends ThumbnailEventCoordinator {
  @override
  ThumbnailBackgroundProgress build() {
    return const ThumbnailBackgroundProgress();
  }
}

class _FakeSettingsNotifier extends SettingsNotifier {
  _FakeSettingsNotifier(this._setting);

  final AppSetting _setting;

  @override
  Future<AppSetting> build() async => _setting;
}

class _MutableSettingsNotifier extends SettingsNotifier {
  _MutableSettingsNotifier(this._setting);

  AppSetting _setting;

  @override
  Future<AppSetting> build() async => _setting;

  @override
  Future<void> setLocalePreference(AppLocalePreference value) async {
    _setting = _setting.copyWith(localePreference: value);
    state = AsyncData<AppSetting>(_setting);
  }
}

class _FakeAppUpdateCoordinator extends AppUpdateCoordinatorNotifier {
  @override
  bool build() => true;
}

class _FakeAppStartupCoordinator extends AppStartupCoordinatorNotifier {
  @override
  bool build() => true;
}
