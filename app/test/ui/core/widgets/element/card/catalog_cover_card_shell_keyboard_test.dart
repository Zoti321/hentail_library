import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/element/card/catalog_cover_card_shell.dart';

void main() {
  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });

  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  testWidgets('ActivateIntent on a focused card invokes onTap', (
    WidgetTester tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 360,
            child: CatalogCoverCardShell(
              semanticLabel: 'Sample comic',
              onTap: () => tapped = true,
              cover: const ColoredBox(color: Colors.grey),
              info: (_) => const Text('title'),
            ),
          ),
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(tapped, isTrue);
    expect(
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<CatalogCoverCardShell>(),
      isNotNull,
    );
  });

  testWidgets('Tab focus uses primary border and hover shadow', (
    WidgetTester tester,
  ) async {
    final ThemeData theme = buildAppTheme(Brightness.light);
    final ColorScheme cs = theme.colorScheme;
    final HentaiColorScheme h = cs.hentai;

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 360,
            child: CatalogCoverCardShell(
              semanticLabel: 'Sample comic',
              onTap: () {},
              cover: const ColoredBox(color: Colors.grey),
              info: (_) => const Text('title'),
            ),
          ),
        ),
      ),
    );

    BoxDecoration idle = _cardDecoration(tester);
    expect(_borderColor(idle), h.borderSubtle);
    expect(idle.boxShadow!.single.color, h.cardShadow);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final BoxDecoration focused = _cardDecoration(tester);
    expect(_borderColor(focused), cs.primary);
    expect(focused.boxShadow!.single.color, h.cardShadowHover);
  });

  testWidgets('pointer tap unfocuses and restores idle chrome', (
    WidgetTester tester,
  ) async {
    final ThemeData theme = buildAppTheme(Brightness.light);
    final ColorScheme cs = theme.colorScheme;
    final HentaiColorScheme h = cs.hentai;

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 360,
            child: CatalogCoverCardShell(
              semanticLabel: 'Sample comic',
              onTap: () {},
              cover: const ColoredBox(color: Colors.grey),
              info: (_) => const Text('title'),
            ),
          ),
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(_borderColor(_cardDecoration(tester)), cs.primary);
    expect(
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<CatalogCoverCardShell>(),
      isNotNull,
    );

    await tester.tap(find.byType(CatalogCoverCardShell));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<CatalogCoverCardShell>(),
      isNull,
    );
    final BoxDecoration idle = _cardDecoration(tester);
    expect(_borderColor(idle), h.borderSubtle);
    expect(idle.boxShadow!.single.color, h.cardShadow);
  });
}

BoxDecoration _cardDecoration(WidgetTester tester) {
  final AnimatedContainer container = tester.widget(
    find.byType(AnimatedContainer),
  );
  return container.decoration! as BoxDecoration;
}

Color _borderColor(BoxDecoration decoration) {
  return (decoration.border! as Border).top.color;
}
