import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/form/fluent_select_field.dart';

enum _TestOption { alpha, beta }

void main() {
  testWidgets('FluentSelectField renders label and invokes onChanged', (
    WidgetTester tester,
  ) async {
    _TestOption selected = _TestOption.alpha;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return FluentSelectField<_TestOption>(
                labelText: 'Status',
                value: selected,
                items: _TestOption.values,
                itemLabel: (_TestOption option) => switch (option) {
                  _TestOption.alpha => 'Alpha',
                  _TestOption.beta => 'Beta',
                },
                onChanged: (_TestOption? value) {
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
    );
    await tester.pumpAndSettle();

    expect(find.text('STATUS'), findsOneWidget);
    expect(find.text('Alpha'), findsOneWidget);

    await tester.tap(find.text('Alpha'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Beta').last);
    await tester.pumpAndSettle();

    expect(selected, _TestOption.beta);
    expect(find.text('Beta'), findsOneWidget);
  });
}
