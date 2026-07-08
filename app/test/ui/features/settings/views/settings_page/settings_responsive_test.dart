import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/models/app_setting.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/features/settings/view_models/settings_notifier.dart';
import 'package:hentai_library/ui/providers.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/settings_loaded_view.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/settings_layout_constants.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/settings_page_header.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod/misc.dart' show Override;

void main() {
  group('Settings responsive layout', () {
    testWidgets('compact page hides row descriptions without overflow', (
      WidgetTester tester,
    ) async {
      await _pumpSettingsView(tester, viewportWidth: 360);

      expect(tester.takeException(), isNull);
      final Text title = tester.widget<Text>(find.text('设置'));
      expect(title.style?.fontSize, 18);
      expect(find.text('管理扫描路径'), findsNothing);
      expect(find.textContaining('当前：'), findsNothing);
      expect(find.byType(SettingsPageHeaderSection), findsOneWidget);
      _expectMenuIcon(tester, findsOneWidget);
    });

    testWidgets('medium page shows row descriptions and medium title', (
      WidgetTester tester,
    ) async {
      await _pumpSettingsView(tester, viewportWidth: 700);

      expect(tester.takeException(), isNull);
      final Text title = tester.widget<Text>(find.text('设置'));
      expect(title.style?.fontSize, 22);
      expect(find.text('管理扫描路径'), findsOneWidget);
      expect(find.textContaining('当前：'), findsOneWidget);
      _expectMenuIcon(tester, findsNothing);
    });

    testWidgets('expanded page uses expanded title size', (
      WidgetTester tester,
    ) async {
      await _pumpSettingsView(tester, viewportWidth: 1200);

      expect(tester.takeException(), isNull);
      final Text title = tester.widget<Text>(find.text('设置'));
      expect(title.style?.fontSize, 26);
    });

    testWidgets('compact theme row hides preference text button', (
      WidgetTester tester,
    ) async {
      await _pumpSettingsView(tester, viewportWidth: 360);

      expect(settingsThemeRowUsesChevronAction(SettingsLayoutTier.compact), isTrue);
      expect(find.text('跟随系统'), findsNothing);
    });

    testWidgets('medium theme row shows preference text button', (
      WidgetTester tester,
    ) async {
      await _pumpSettingsView(tester, viewportWidth: 700);

      expect(find.text('跟随系统'), findsOneWidget);
    });
  });
}

Future<void> _pumpSettingsView(
  WidgetTester tester, {
  required double viewportWidth,
}) async {
  tester.view.physicalSize = Size(viewportWidth, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    ProviderScope(
      overrides: _settingsViewTestOverrides(),
      child: MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: SizedBox(
            width: viewportWidth,
            height: 800,
            child: const SettingsView(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void _expectMenuIcon(WidgetTester tester, Matcher matcher) {
  expect(
    find.byWidgetPredicate(
      (Widget widget) => widget is Icon && widget.icon == LucideIcons.menu,
    ),
    matcher,
  );
}

List<Override> _settingsViewTestOverrides() {
  return <Override>[
    settingsProvider.overrideWith(_FakeSettingsNotifier.new),
    packageInfoProvider.overrideWith(
      (Ref ref) async => PackageInfo(
        appName: 'Hentai Library',
        packageName: 'hentai_library',
        version: '1.0.0',
        buildNumber: '1',
      ),
    ),
  ];
}

class _FakeSettingsNotifier extends SettingsNotifier {
  @override
  Future<AppSetting> build() async => AppSetting();
}
