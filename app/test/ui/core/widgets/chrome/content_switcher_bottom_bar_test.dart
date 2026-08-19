import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/chrome/content_switcher_bottom_bar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  group('ContentSwitcherBottomBar', () {
    testWidgets('renders an icon above each item label', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(Brightness.light),
          home: Scaffold(
            bottomNavigationBar: ContentSwitcherBottomBar(
              items: const <ContentSwitcherBottomBarItem>[
                (icon: LucideIcons.bookImage, label: 'Comics'),
                (icon: LucideIcons.bookMarked, label: 'Series'),
              ],
              selectedIndex: 0,
              onSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Comics'), findsOneWidget);
      expect(find.text('Series'), findsOneWidget);
      expect(find.byIcon(LucideIcons.bookImage), findsOneWidget);
      expect(find.byIcon(LucideIcons.bookMarked), findsOneWidget);
    });

    testWidgets('selected item uses primary tint background', (
      WidgetTester tester,
    ) async {
      final ThemeData theme = buildAppTheme(Brightness.light);

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            bottomNavigationBar: ContentSwitcherBottomBar(
              items: const <ContentSwitcherBottomBarItem>[
                (icon: LucideIcons.bookImage, label: 'Comics'),
                (icon: LucideIcons.bookMarked, label: 'Series'),
              ],
              selectedIndex: 0,
              onSelected: (_) {},
            ),
          ),
        ),
      );

      final Iterable<Material> tintedMaterials = tester
          .widgetList<Material>(
            find.descendant(
              of: find.byType(ContentSwitcherBottomBar),
              matching: find.byType(Material),
            ),
          )
          .where(
            (Material material) =>
                material.color == theme.colorScheme.primary.withAlpha(28),
          );
      expect(tintedMaterials, isNotEmpty);
    });
  });
}
