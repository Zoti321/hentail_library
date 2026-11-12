import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../support/pump_app.dart';

Future<void> _pumpBar(
  WidgetTester tester, {
  bool destructive = false,
  bool confirmEnabled = true,
  bool saving = false,
  VoidCallback? onCancel,
  VoidCallback? onConfirm,
}) async {
  await pumpApp(
    tester,
    home: Scaffold(
      body: Center(
        child: DialogActionBar(
          onCancel: onCancel ?? () {},
          onConfirm: onConfirm ?? () {},
          confirmLabel: '确认',
          cancelLabel: '取消',
          destructive: destructive,
          confirmEnabled: confirmEnabled,
          saving: saving,
        ),
      ),
    ),
  );
}

M3EButton _buttonWithLabel(WidgetTester tester, String label) {
  return tester.widget<M3EButton>(
    find.ancestor(
      of: find.text(label),
      matching: find.byType(M3EButton),
    ).first,
  );
}

void main() {
  testWidgets('取消与确认分别触发回调', (WidgetTester tester) async {
    int cancels = 0;
    int confirms = 0;
    await _pumpBar(
      tester,
      onCancel: () => cancels++,
      onConfirm: () => confirms++,
    );

    await tester.tap(find.text('取消'));
    await tester.tap(find.text('确认'));

    expect(cancels, 1);
    expect(confirms, 1);
  });

  testWidgets('destructive 时确认按钮使用 error 底色', (WidgetTester tester) async {
    await _pumpBar(tester, destructive: true);

    final BuildContext context = tester.element(find.byType(DialogActionBar));
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final M3EButton confirm = _buttonWithLabel(tester, '确认');

    expect(
      confirm.decoration!.backgroundColor!.resolve(const <WidgetState>{}),
      scheme.error,
    );
  });

  testWidgets('confirmEnabled=false 时确认按钮禁用', (WidgetTester tester) async {
    await _pumpBar(tester, confirmEnabled: false);

    expect(_buttonWithLabel(tester, '确认').onPressed, isNull);
    expect(_buttonWithLabel(tester, '取消').onPressed, isNotNull);
  });

  testWidgets('saving=true 时显示行内进度且两键禁用', (WidgetTester tester) async {
    await _pumpBar(tester, saving: true);

    expect(find.byType(M3EProgressIndicator), findsOneWidget);
    expect(_buttonWithLabel(tester, '确认').onPressed, isNull);
    expect(_buttonWithLabel(tester, '取消').onPressed, isNull);
  });
}
