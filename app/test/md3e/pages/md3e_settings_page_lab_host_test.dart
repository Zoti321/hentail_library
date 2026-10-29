import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/pages/md3e_settings_page_lab_host.dart';
import 'package:hentai_library/md3e/patterns/settings/md3e_settings_catalog.dart';

import '../../support/pump_md3e_app.dart';

void main() {
  testWidgets('阅读模式 tile 点击后切换 preview 值', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpMd3eApp(
      tester,
      home: const Md3eSettingsPageLabHost(
        initialCategory: Md3eSettingsCategory.personalization,
      ),
    );

    expect(find.text('阅读模式'), findsOneWidget);
    expect(find.text('单页'), findsOneWidget);

    await tester.tap(find.text('阅读模式'));
    await tester.pumpAndSettle();

    expect(find.text('单页'), findsNothing);
    expect(find.text('双页'), findsOneWidget);
  });

  testWidgets('Healthy mode 开关切换 preview 状态', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpMd3eApp(
      tester,
      home: const Md3eSettingsPageLabHost(
        initialCategory: Md3eSettingsCategory.personalization,
      ),
    );

    Switch healthySwitch() => tester.widget<Switch>(find.byType(Switch).first);

    expect(find.text('Healthy mode'), findsOneWidget);
    expect(healthySwitch().value, isFalse);

    await tester.tap(find.text('Healthy mode'));
    await tester.pumpAndSettle();

    expect(healthySwitch().value, isTrue);
  });
}
