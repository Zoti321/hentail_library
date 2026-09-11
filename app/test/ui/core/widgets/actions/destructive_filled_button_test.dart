import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/destructive_filled_button.dart';

void main() {
  group('DestructiveFilledButton', () {
    testWidgets('enabled uses destructive / onDestructive fill', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(Brightness.light),
          home: const Scaffold(
            body: DestructiveFilledButton(
              onPressed: _noop,
              child: Text('Delete'),
            ),
          ),
        ),
      );

      final HentaiColorScheme h = buildAppTheme(
        Brightness.light,
      ).colorScheme.hentai;
      final FilledButton button = tester.widget(find.byType(FilledButton));
      final Set<WidgetState> enabled = <WidgetState>{};

      expect(
        button.style?.backgroundColor?.resolve(enabled),
        h.destructive,
      );
      expect(
        button.style?.foregroundColor?.resolve(enabled),
        h.onDestructive,
      );
    });

    testWidgets('disabled keeps destructive family instead of grey primary', (
      WidgetTester tester,
    ) async {
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

      final HentaiColorScheme h = buildAppTheme(
        Brightness.light,
      ).colorScheme.hentai;
      final ColorScheme cs = buildAppTheme(Brightness.light).colorScheme;
      final FilledButton button = tester.widget(find.byType(FilledButton));
      const Set<WidgetState> disabled = <WidgetState>{WidgetState.disabled};

      final Color? disabledBg = button.style?.backgroundColor?.resolve(
        disabled,
      );
      final Color? disabledFg = button.style?.foregroundColor?.resolve(
        disabled,
      );

      expect(disabledBg, isNotNull);
      expect(disabledFg, isNotNull);
      expect(disabledBg, isNot(cs.primary.withValues(alpha: 0.12)));
      expect(disabledBg!.r, closeTo(h.destructive.r, 0.02));
      expect(disabledBg.g, closeTo(h.destructive.g, 0.02));
      expect(disabledBg.b, closeTo(h.destructive.b, 0.02));
      expect(disabledBg.a, lessThan(1.0));
      expect(disabledFg!.r, closeTo(h.onDestructive.r, 0.02));
      expect(disabledFg.g, closeTo(h.onDestructive.g, 0.02));
      expect(disabledFg.b, closeTo(h.onDestructive.b, 0.02));
    });
  });
}

void _noop() {}
