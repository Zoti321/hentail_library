import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/form/fluent_select_field.dart';

enum _TestOption { alpha, beta, gamma }

String _labelOf(_TestOption option) => switch (option) {
  _TestOption.alpha => 'Alpha',
  _TestOption.beta => 'Beta',
  _TestOption.gamma => 'Gamma',
};

Future<_TestOption> _pumpSelect(
  WidgetTester tester, {
  _TestOption initial = _TestOption.alpha,
  bool enabled = true,
  Alignment alignment = Alignment.topCenter,
  Size surfaceSize = const Size(800, 600),
  FluentSelectMenuStyle? menuStyle,
  ValueChanged<_TestOption?>? onChanged,
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
  });

  _TestOption selected = initial;

  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(Brightness.light),
      home: Scaffold(
        body: Align(
          alignment: alignment,
          child: SizedBox(
            width: 240,
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return FluentSelectField<_TestOption>(
                  labelText: 'Status',
                  value: selected,
                  items: _TestOption.values,
                  itemLabel: _labelOf,
                  enabled: enabled,
                  menuStyle: menuStyle,
                  onChanged: (_TestOption? value) {
                    onChanged?.call(value);
                    if (value == null) {
                      return;
                    }
                    setState(() => selected = value);
                  },
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return selected;
}

void main() {
  testWidgets('opens menu and selects another item via onChanged', (
    WidgetTester tester,
  ) async {
    _TestOption? changed;

    await _pumpSelect(
      tester,
      onChanged: (_TestOption? value) => changed = value,
    );

    expect(find.text('STATUS'), findsOneWidget);
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.byKey(FluentSelectField.menuPanelKey), findsNothing);

    await tester.tap(find.byKey(FluentSelectField.triggerKey));
    await tester.pumpAndSettle();

    expect(find.byKey(FluentSelectField.menuPanelKey), findsOneWidget);
    expect(find.text('Beta'), findsWidgets);

    await tester.tap(find.text('Beta').last);
    await tester.pumpAndSettle();

    expect(changed, _TestOption.beta);
    expect(find.byKey(FluentSelectField.menuPanelKey), findsNothing);
    expect(find.text('Beta'), findsOneWidget);
  });

  testWidgets('flips menu above when space below is insufficient', (
    WidgetTester tester,
  ) async {
    await _pumpSelect(
      tester,
      alignment: Alignment.bottomCenter,
      surfaceSize: const Size(400, 320),
      menuStyle: fluentSelectMenuStyle(menuGap: 4),
    );

    await tester.tap(find.byKey(FluentSelectField.triggerKey));
    await tester.pumpAndSettle();

    final Rect triggerRect = tester.getRect(
      find.byKey(FluentSelectField.triggerKey),
    );
    final Rect menuRect = tester.getRect(
      find.byKey(FluentSelectField.menuPanelKey),
    );

    expect(menuRect.bottom, lessThanOrEqualTo(triggerRect.top + 0.5));
  });

  testWidgets('menu width matches trigger field width', (
    WidgetTester tester,
  ) async {
    await _pumpSelect(tester);

    await tester.tap(find.byKey(FluentSelectField.triggerKey));
    await tester.pumpAndSettle();

    final Rect triggerRect = tester.getRect(
      find.byKey(FluentSelectField.triggerKey),
    );
    final Rect menuRect = tester.getRect(
      find.byKey(FluentSelectField.menuPanelKey),
    );

    expect(menuRect.width, moreOrLessEquals(triggerRect.width, epsilon: 0.5));
  });

  testWidgets('tapping outside closes menu without changing value', (
    WidgetTester tester,
  ) async {
    _TestOption? changed;

    await _pumpSelect(
      tester,
      onChanged: (_TestOption? value) => changed = value,
    );

    await tester.tap(find.byKey(FluentSelectField.triggerKey));
    await tester.pumpAndSettle();
    expect(find.byKey(FluentSelectField.menuPanelKey), findsOneWidget);

    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();

    expect(find.byKey(FluentSelectField.menuPanelKey), findsNothing);
    expect(changed, isNull);
    expect(find.text('Alpha'), findsOneWidget);
  });

  testWidgets('disabled field does not open menu', (WidgetTester tester) async {
    await _pumpSelect(tester, enabled: false);

    await tester.tap(find.byKey(FluentSelectField.triggerKey));
    await tester.pumpAndSettle();

    expect(find.byKey(FluentSelectField.menuPanelKey), findsNothing);
  });
}
