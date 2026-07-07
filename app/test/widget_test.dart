import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/models/app_setting.dart';
import 'package:hentai_library/ui/providers/comic_cover_providers.dart';
import 'package:hentai_library/ui/features/settings/state/app_update_coordinator_notifier.dart';
import 'package:hentai_library/ui/features/settings/view_models/settings_notifier.dart';
import 'package:hentai_library/ui/features/shell/state/app_startup_coordinator_notifier.dart';
import 'package:hentai_library/ui/features/shell/views/app.dart';
import 'package:riverpod/misc.dart' show Override;

void main() {
  testWidgets('MyApp smoke test - pumps without crash and builds app', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(MyApp(overrides: _smokeTestOverrides()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

List<Override> _smokeTestOverrides() {
  return <Override>[
    thumbnailEventCoordinatorProvider.overrideWith(
      _FakeThumbnailEventCoordinator.new,
    ),
    settingsProvider.overrideWith(_FakeSettingsNotifier.new),
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
  @override
  Future<AppSetting> build() async => AppSetting();
}

class _FakeAppUpdateCoordinator extends AppUpdateCoordinatorNotifier {
  @override
  bool build() => true;
}

class _FakeAppStartupCoordinator extends AppStartupCoordinatorNotifier {
  @override
  bool build() => true;
}
