import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/settings_loaded_view.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/settings_layout_constants.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/settings_page_header.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../support/fakes/settings_test_fakes.dart';
import '../../../../../support/pump_localized_app.dart';

void main() {
  group('Settings responsive layout', () {
    testWidgets('compact page shows check-update row without overflow', (
      WidgetTester tester,
    ) async {
      await _pumpSettingsView(tester, viewportWidth: 360);

      expect(tester.takeException(), isNull);
      final Text title = tester.widget<Text>(find.text('设置'));
      expect(title.style?.fontSize, 18);
      expect(find.text('管理扫描路径'), findsNothing);
      expect(find.textContaining('当前：'), findsNothing);
      expect(find.textContaining('已启用'), findsNothing);
      expect(find.textContaining('已禁用'), findsNothing);
      expect(find.text('检查更新'), findsOneWidget);
      expect(find.text('当前版本 v1.0.0'), findsOneWidget);
      expect(find.byType(SettingsPageHeaderSection), findsOneWidget);
      _expectMenuIcon(tester, findsOneWidget);
    });

    testWidgets('medium page keeps check-update row and medium title', (
      WidgetTester tester,
    ) async {
      await _pumpSettingsView(tester, viewportWidth: 700);

      expect(tester.takeException(), isNull);
      final Text title = tester.widget<Text>(find.text('设置'));
      expect(title.style?.fontSize, 22);
      expect(find.text('管理扫描路径'), findsNothing);
      expect(find.textContaining('当前：'), findsNothing);
      expect(find.text('检查更新'), findsOneWidget);
      expect(find.text('当前版本 v1.0.0'), findsOneWidget);
      _expectMenuIcon(tester, findsNothing);
    });

    testWidgets('expanded page uses expanded title size', (
      WidgetTester tester,
    ) async {
      await _pumpSettingsView(tester, viewportWidth: 1200);

      expect(tester.takeException(), isNull);
      final Text title = tester.widget<Text>(find.text('设置'));
      expect(title.style?.fontSize, 26);
      expect(find.text('检查更新'), findsOneWidget);
      expect(find.text('当前版本 v1.0.0'), findsOneWidget);
    });

    testWidgets('compact theme row hides preference text button', (
      WidgetTester tester,
    ) async {
      await _pumpSettingsView(tester, viewportWidth: 360);

      expect(
        settingsThemeRowUsesChevronAction(SettingsLayoutTier.compact),
        isTrue,
      );
      expect(find.text('跟随系统'), findsNothing);
    });

    testWidgets('medium theme row shows preference text button', (
      WidgetTester tester,
    ) async {
      await _pumpSettingsView(tester, viewportWidth: 700);

      // Theme + language rows both default to "跟随系统".
      expect(find.text('跟随系统'), findsNWidgets(2));
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

  await pumpLocalizedApp(
    tester,
    wrapProviderScope: true,
    overrides: settingsViewTestOverrides(),
    home: Scaffold(
      body: SizedBox(
        width: viewportWidth,
        height: 800,
        child: const SettingsView(),
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
