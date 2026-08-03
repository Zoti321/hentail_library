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

  testWidgets('inline label layout places label beside 180-wide trigger', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: FluentSelectField<_TestOption>(
              labelText: 'Reading mode',
              labelLayout: FluentSelectLabelLayout.inline,
              value: _TestOption.alpha,
              items: _TestOption.values,
              itemLabel: _labelOf,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Reading mode'), findsOneWidget);
    expect(find.text('READING MODE'), findsNothing);

    final Rect labelRect = tester.getRect(find.text('Reading mode'));
    final Rect triggerRect = tester.getRect(
      find.byKey(FluentSelectField.triggerKey),
    );

    expect(
      labelRect.center.dy,
      moreOrLessEquals(triggerRect.center.dy, epsilon: 6),
    );
    expect(labelRect.right, lessThanOrEqualTo(triggerRect.left + 0.5));
    expect(triggerRect.width, moreOrLessEquals(180, epsilon: 0.5));
  });

  testWidgets('menu height caps at default 240 and remains scrollable', (
    WidgetTester tester,
  ) async {
    final List<int> items = List<int>.generate(40, (int i) => i);
    int? selected = 0;

    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 240,
              child: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return FluentSelectField<int>(
                    labelText: 'Margin',
                    value: selected!,
                    items: items,
                    itemLabel: (int v) => 'Item $v',
                    onChanged: (int? value) {
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

    await tester.tap(find.byKey(FluentSelectField.triggerKey));
    await tester.pumpAndSettle();

    final Rect menuRect = tester.getRect(
      find.byKey(FluentSelectField.menuPanelKey),
    );
    expect(
      menuRect.height,
      lessThanOrEqualTo(kFluentSelectMenuMaxHeight + 0.5),
    );

    await tester.scrollUntilVisible(
      find.text('Item 39'),
      80,
      scrollable: find
          .descendant(
            of: find.byKey(FluentSelectField.menuPanelKey),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Item 39'));
    await tester.pumpAndSettle();

    expect(selected, 39);
    expect(find.text('Item 39'), findsOneWidget);
  });

  testWidgets('menu height respects explicit smaller menuMaxHeight', (
    WidgetTester tester,
  ) async {
    final List<int> items = List<int>.generate(40, (int i) => i);

    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 240,
              child: FluentSelectField<int>(
                labelText: 'Margin',
                value: 0,
                items: items,
                itemLabel: (int v) => 'Item $v',
                menuStyle: fluentSelectMenuStyle(menuMaxHeight: 120),
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(FluentSelectField.triggerKey));
    await tester.pumpAndSettle();

    final Rect menuRect = tester.getRect(
      find.byKey(FluentSelectField.menuPanelKey),
    );
    expect(menuRect.height, lessThanOrEqualTo(120.5));
  });

  testWidgets('menu overlay keeps dark theme under light app theme', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    final ThemeData darkTheme = buildAppTheme(Brightness.dark);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: Theme(
            data: darkTheme,
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: 240,
                child: FluentSelectField<_TestOption>(
                  labelText: 'Status',
                  value: _TestOption.alpha,
                  items: _TestOption.values,
                  itemLabel: _labelOf,
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(FluentSelectField.triggerKey));
    await tester.pumpAndSettle();

    final BuildContext menuContext = tester.element(
      find.byKey(FluentSelectField.menuPanelKey),
    );
    expect(Theme.of(menuContext).brightness, Brightness.dark);
  });
}
