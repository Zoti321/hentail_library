import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';
import 'package:hentai_library/shared/ui/widgets/actions/destructive_filled_button.dart';

void main() {
  group('DestructiveFilledButton', () {
    testWidgets('uses ColorScheme error roles when enabled', (
      WidgetTester tester,
    ) async {
      final ColorScheme cs = buildAppTheme(Brightness.light).colorScheme;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(Brightness.light),
          home: Scaffold(
            body: DestructiveFilledButton(
              onPressed: () {},
              child: const Text('Delete'),
            ),
          ),
        ),
      );

      final FilledButton button = tester.widget(find.byType(FilledButton));
      final ButtonStyle style = button.style!;
      expect(
        style.backgroundColor!.resolve(<WidgetState>{}),
        cs.error,
      );
      expect(
        style.foregroundColor!.resolve(<WidgetState>{}),
        cs.onError,
      );
    });

    testWidgets('keeps error hue when disabled', (WidgetTester tester) async {
      final ColorScheme cs = buildAppTheme(Brightness.light).colorScheme;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(Brightness.light),
          home: const Scaffold(
            body: DestructiveFilledButton(
              onPressed: null,
              child: Text('Delete'),
            ),
          ),
        ),
      );

      final FilledButton button = tester.widget(find.byType(FilledButton));
      final ButtonStyle style = button.style!;
      expect(
        style.backgroundColor!.resolve(<WidgetState>{WidgetState.disabled}),
        cs.error.withAlpha(102),
      );
      expect(
        style.foregroundColor!.resolve(<WidgetState>{WidgetState.disabled}),
        cs.onError.withAlpha(153),
      );
    });
  });
}
