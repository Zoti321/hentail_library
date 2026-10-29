import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/data/md3e_lab_library_catalog.dart';
import 'package:hentai_library/md3e/patterns/desktop/md3e_desktop_shell.dart';
import 'package:hentai_library/md3e/patterns/desktop/md3e_shell_compact_app_bar.dart';
import 'package:hentai_library/md3e/patterns/desktop/md3e_shell_navigation.dart';
import 'package:hentai_library/md3e/patterns/desktop/md3e_shell_rail_library_hover_metrics.dart';
import 'package:hentai_library/md3e/widgets/desktop/md3e_desktop_title_bar.dart';
import 'package:hentai_library/md3e/widgets/desktop/md3e_navigation_rail.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../support/pump_md3e_app.dart';

Future<void> _hoverLibraryRailDestination(WidgetTester tester) async {
  final M3EThemeData theme = M3ETheme.of(
    tester.element(find.byType(Md3eDesktopShell)),
  );
  final M3ENavigationRailTheme navTheme = theme.navigationRailTheme;
  final int libraryIndex =
      Md3eShellRailLibraryHoverMetrics.libraryDestinationIndex;
  final double top = Md3eShellRailLibraryHoverMetrics.destinationTop(
    theme: navTheme,
    railExtended: false,
    destinationIndex: libraryIndex,
  );
  final double height = Md3eShellRailLibraryHoverMetrics.destinationHeight(
    theme: navTheme,
    railExtended: false,
  );
  final Rect railRect = tester.getRect(find.byType(Md3eNavigationRail));
  final Offset center = Offset(
    railRect.left + railRect.width / 2,
    railRect.top + top + height / 2,
  );
  final TestGesture gesture = await tester.createGesture(
    kind: PointerDeviceKind.mouse,
  );
  await gesture.moveTo(center);
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('expanded width shows navigation rail', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1024, 768));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpMd3eApp(
      tester,
      home: Md3eDesktopShell(
        width: 1024,
        height: 768,
        initialRailExtended: false,
      ),
    );

    expect(find.byType(Md3eNavigationRail), findsOneWidget);
    expect(find.byType(Md3eDesktopTitleBar), findsOneWidget);
    expect(find.byType(Md3eDesktopShellPane), findsOneWidget);
    expect(find.byType(M3ESearchBar), findsOneWidget);
  });

  testWidgets(
    'below expanded breakpoint uses compact app bar not desktop search',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 768));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpMd3eApp(
        tester,
        home: Md3eDesktopShell(width: 600, height: 768),
      );

      expect(find.byType(Md3eShellCompactAppBar), findsOneWidget);
      expect(find.byType(Md3eNavigationRail), findsNothing);
      expect(find.byType(M3ESearchBar), findsNothing);
      expect(find.byIcon(Icons.menu), findsOneWidget);
    },
  );

  testWidgets('below expanded breakpoint hides desktop window controls', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(600, 768));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpMd3eApp(tester, home: Md3eDesktopShell(width: 600, height: 768));

    expect(find.byIcon(Icons.remove), findsNothing);
    expect(find.byIcon(Icons.close), findsNothing);
  });

  testWidgets('title bar search leading inset is flush with pane column', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1024, 768));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpMd3eApp(tester, home: Md3eDesktopShell(width: 1024, height: 768));

    final Finder titleBar = find.byType(Md3eDesktopTitleBar);
    final Finder pane = find.byType(Md3eDesktopShellPane);

    final Rect titleBarRect = tester.getRect(titleBar);
    final Rect paneRect = tester.getRect(pane);

    expect(titleBarRect.left, paneRect.left);
  });

  testWidgets('search field is inset from content card leading edge', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1024, 768));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpMd3eApp(tester, home: Md3eDesktopShell(width: 1024, height: 768));
    await tester.pumpAndSettle();

    final Rect searchRect = tester.getRect(find.byType(M3ESearchBar));
    final Finder shellClip = find.descendant(
      of: find.byType(Md3eDesktopShell),
      matching: find.byWidgetPredicate(
        (Widget widget) =>
            widget is ClipRRect &&
            widget.borderRadius ==
                Md3eDesktopShellMetrics.contentCardLeadingRadius(),
      ),
    );
    final Rect clipRect = tester.getRect(shellClip);

    expect(
      searchRect.left,
      clipRect.left + Md3eDesktopShellMetrics.titleBarContentPadding,
    );
  });

  testWidgets(
    'expanded rail at expanded breakpoint does not overflow title bar',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(848, 768));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpMd3eApp(
        tester,
        home: Md3eDesktopShell(
          width: 848,
          height: 768,
          initialRailExtended: true,
        ),
      );

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('compact and medium drill into library secondary from modal rail', (
    WidgetTester tester,
  ) async {
    Future<void> pumpAndSelectLibrary(double width) async {
      const String targetId = 'lab-remote-nas';
      final String targetName = Md3eLabLibraryCatalog.displayNameForId(
        targetId,
      );
      Md3eShellNavigationSnapshot? lastSnapshot;

      await tester.binding.setSurfaceSize(Size(width, 768));
      await pumpMd3eApp(
        tester,
        home: Md3eDesktopShell(
          width: width,
          height: 768,
          paneBuilder: (_, navigation) {
            lastSnapshot = navigation;
            return Text(
              '${navigation.selectedLibraryId}:${navigation.selectedLibraryDisplayName}',
            );
          },
        ),
      );

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);

      await tester.tap(find.text('漫画库'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      await tester.tap(find.text(targetName));
      await tester.pumpAndSettle();

      expect(lastSnapshot?.selectedLibraryId, targetId);
      expect(find.text('$targetId:$targetName'), findsOneWidget);
    }

    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpAndSelectLibrary(390);
    await pumpAndSelectLibrary(600);
  });

  testWidgets(
    'compact settings hides shell menu and back returns to previous destination',
    (WidgetTester tester) async {
      Md3eShellNavigationSnapshot? lastSnapshot;

      await tester.binding.setSurfaceSize(const Size(390, 768));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pumpMd3eApp(
        tester,
        home: Md3eDesktopShell(
          width: 390,
          height: 768,
          paneBuilder: (_, navigation) {
            lastSnapshot = navigation;
            return Text('pane:${navigation.destinationIndex}');
          },
        ),
      );

      final int previousIndex = lastSnapshot!.destinationIndex;
      expect(find.byIcon(Icons.menu), findsOneWidget);

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      expect(
        lastSnapshot?.destinationIndex,
        Md3eShellNavigation.settingsDestinationIndex,
      );
      expect(find.byIcon(Icons.menu), findsNothing);
      expect(lastSnapshot?.onBackToPreviousDestination, isNotNull);

      lastSnapshot!.onBackToPreviousDestination!();
      await tester.pumpAndSettle();

      expect(lastSnapshot?.destinationIndex, previousIndex);
      expect(find.text('pane:$previousIndex'), findsOneWidget);
      expect(find.byIcon(Icons.menu), findsOneWidget);
    },
  );

  testWidgets('expanded shell hover opens library flyout and selects library', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1024, 768));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const String targetId = 'lab-local-archive';
    final String targetName = Md3eLabLibraryCatalog.displayNameForId(targetId);
    Md3eShellNavigationSnapshot? lastSnapshot;

    await pumpMd3eApp(
      tester,
      home: Md3eDesktopShell(
        width: 1024,
        height: 768,
        initialRailExtended: false,
        paneBuilder: (_, navigation) {
          lastSnapshot = navigation;
          return Text(
            '${navigation.selectedLibraryId}:${navigation.selectedLibraryDisplayName}',
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    await _hoverLibraryRailDestination(tester);
    expect(find.text(targetName), findsWidgets);

    await tester.tap(find.text(targetName).last);
    await tester.pumpAndSettle();

    expect(lastSnapshot?.selectedLibraryId, targetId);
    expect(
      lastSnapshot?.destinationIndex,
      Md3eShellNavigation.libraryDestinationIndex,
    );
  });

  testWidgets('title band search aligns at 32dp on expanded shell', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1024, 768));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpMd3eApp(tester, home: Md3eDesktopShell(width: 1024, height: 768));
    await tester.pumpAndSettle();

    const double titleBandCenter = 32;

    expect(
      tester.getRect(find.byIcon(Icons.search)).center.dy,
      titleBandCenter,
    );
    expect(
      tester.getRect(find.byIcon(M3EIcons.menu)).center.dy,
      titleBandCenter,
    );
    expect(
      tester.getRect(find.byIcon(Icons.remove)).center.dy,
      titleBandCenter,
    );
  });
}
