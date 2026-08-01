import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/form/fluent_number_stepper_field.dart';

Future<String> _pumpField(
  WidgetTester tester, {
  String initialValue = '1.0',
  double step = 0.1,
}) async {
  String value = initialValue;

  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(Brightness.light),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 240,
            child: FluentNumberStepperField(
              initialValue: initialValue,
              step: step,
              onChanged: (String next) => value = next,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.byType(TextField));
  await tester.pumpAndSettle();

  return value;
}

void main() {
  testWidgets('steps up and down by 0.1 when focused', (
    WidgetTester tester,
  ) async {
    await _pumpField(tester);

    expect(find.byKey(FluentNumberStepperField.incrementKey), findsOneWidget);
    expect(find.byKey(FluentNumberStepperField.decrementKey), findsOneWidget);

    await tester.tap(find.byKey(FluentNumberStepperField.incrementKey));
    await tester.pumpAndSettle();
    expect(find.text('1.1'), findsOneWidget);

    final TextField fieldAfterStep = tester.widget<TextField>(
      find.byType(TextField),
    );
    expect(fieldAfterStep.controller!.selection.isCollapsed, isTrue);

    await tester.tap(find.byKey(FluentNumberStepperField.decrementKey));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);
    expect(fieldAfterStep.controller!.selection.isCollapsed, isTrue);
  });

  testWidgets('keeps reserved stepper slot height before focus', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 240,
              child: FluentNumberStepperField(
                initialValue: '1',
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Size unfocused = tester.getSize(find.byType(FluentNumberStepperField));
    expect(find.byKey(FluentNumberStepperField.incrementKey), findsOneWidget);

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    final Size focused = tester.getSize(find.byType(FluentNumberStepperField));
    expect(focused.height, unfocused.height);
  });
}
