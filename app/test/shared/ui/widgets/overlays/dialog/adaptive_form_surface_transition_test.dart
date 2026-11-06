import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/ui/widgets/overlays/dialog/adaptive_form_surface.dart';

import '../../../../../support/pump_app.dart';

void main() {
  testWidgets('showAdaptiveFormSurfaceWidget uses FadeScaleTransition', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      home: Builder(
        builder: (BuildContext context) {
          return TextButton(
            onPressed: () {
              // 只断言进场过渡；完整 AdaptiveFormSurface 需 design tokens。
              showAdaptiveFormSurfaceWidget<void>(
                context: context,
                surface: const Material(child: Text('form-body')),
              );
            },
            child: const Text('open'),
          );
        },
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    expect(find.byType(FadeScaleTransition), findsOneWidget);
    expect(find.text('form-body'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('form-body'), findsOneWidget);
  });
}
