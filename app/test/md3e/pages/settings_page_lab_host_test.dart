import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hentai_library/features/app_settings/presentation/patterns/settings/settings_catalog.dart';

import '../../../widgetbook/hosts/md3e_settings_page_lab_host.dart';
import '../../support/pump_app.dart';

void main() {
  testWidgets('阅读模式 tile 点击后切换 preview 值', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpApp(
      tester,
      home: const SettingsPageLabHost(
        initialCategory: SettingsCategory.reading,
      ),
    );

    expect(find.text('阅读模式'), findsWidgets);
    expect(find.text('翻页'), findsOneWidget);

    await tester.tap(find.text('翻页'));
    await tester.pumpAndSettle();

    expect(find.text('翻页'), findsNothing);
    expect(find.text('Webtoon'), findsOneWidget);
  });

  testWidgets('Healthy mode 开关切换 preview 状态', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpApp(
      tester,
      home: const SettingsPageLabHost(
        initialCategory: SettingsCategory.libraryBrowse,
      ),
    );

    Switch healthySwitch() => tester.widget<Switch>(find.byType(Switch).first);

    expect(find.text('健康模式'), findsOneWidget);
    expect(healthySwitch().value, isFalse);

    await tester.tap(find.text('健康模式'));
    await tester.pumpAndSettle();

    expect(healthySwitch().value, isTrue);
  });
}
