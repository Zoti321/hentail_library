import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/design-system/design_system.dart';

import '../../support/pump_design_system_app.dart';

void main() {
  for (final locale in ['zh', 'en']) {
    testWidgets('$locale component semantics work without application ARBs', (
      tester,
    ) async {
      final clear = locale == 'zh' ? '清空' : 'Clear';
      final back = locale == 'zh' ? '返回' : 'Back';
      final controller = TextEditingController(text: 'value');
      addTearDown(controller.dispose);
      final semantics = tester.ensureSemantics();
      await pumpDesignSystemApp(
        tester,
        locale: Locale(locale),
        home: Column(
          children: [
            PageHeaderBackButton(onPressed: () {}),
            OutlinedTextField(
              label: 'Input',
              controller: controller,
              showClearButton: true,
            ),
          ],
        ),
      );
      expect(find.bySemanticsLabel(back), findsOneWidget);
      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(clear), findsOneWidget);
      await tester.tap(find.bySemanticsLabel(clear));
      await tester.pumpAndSettle();
      expect(controller.text, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      semantics.dispose();
    });
  }
}
