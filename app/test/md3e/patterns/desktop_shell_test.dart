import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/ui/lab/lab_library_catalog.dart';
import 'package:hentai_library/shared/ui/shell/desktop_shell.dart';
import 'package:hentai_library/shared/ui/shell/shell_rail_library_hover_metrics.dart';
import 'package:hentai_library/shared/ui/widgets/desktop/desktop_title_bar.dart';
import 'package:hentai_library/shared/ui/widgets/desktop/navigation_bar.dart';
import 'package:hentai_library/shared/ui/widgets/desktop/navigation_rail.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../support/pump_app.dart';

Future<void> _hoverLibraryRailDestination(WidgetTester tester) async {
  final M3EThemeData theme = M3ETheme.of(
    tester.element(find.byType(DesktopShell)),
  );
  final M3ENavigationRailTheme navTheme = theme.navigationRailTheme;
  final int libraryIndex = ShellRailLibraryHoverMetrics.libraryDestinationIndex;
  final double top = ShellRailLibraryHoverMetrics.destinationTop(
    theme: navTheme,
    railExtended: false,
    destinationIndex: libraryIndex,
  );
  final double height = ShellRailLibraryHoverMetrics.destinationHeight(
    theme: navTheme,
    railExtended: false,
  );
  final Rect railRect = tester.getRect(find.byType(ExpressiveNavigationRail));
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

    await pumpApp(
      tester,
      home: DesktopShell(width: 1024, height: 768, initialRailExtended: false),
    );

    expect(find.byType(ExpressiveNavigationRail), findsOneWidget);
    expect(find.byType(ExpressiveNavigationBar), findsNothing);
    expect(find.byType(DesktopTitleBar), findsOneWidget);
    expect(find.byType(DesktopShellPane), findsOneWidget);
  });

  testWidgets(
    'below expanded breakpoint uses bottom navigation without drawer menu',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 768));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpApp(tester, home: DesktopShell(width: 600, height: 768));

      expect(find.byType(ExpressiveNavigationBar), findsOneWidget);
      expect(find.byType(ExpressiveNavigationRail), findsNothing);
      expect(find.byIcon(Icons.menu), findsNothing);
    },
  );

  testWidgets('below expanded breakpoint hides desktop window controls', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(600, 768));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpApp(tester, home: DesktopShell(width: 600, height: 768));

    expect(find.byIcon(Icons.remove), findsNothing);
    expect(find.byIcon(Icons.close), findsNothing);
  });

  testWidgets('title bar is flush with pane column', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1024, 768));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpApp(tester, home: DesktopShell(width: 1024, height: 768));

    final Finder titleBar = find.byType(DesktopTitleBar);
    final Finder pane = find.byType(DesktopShellPane);

    final Rect titleBarRect = tester.getRect(titleBar);
    final Rect paneRect = tester.getRect(pane);

    expect(titleBarRect.left, paneRect.left);
  });

  testWidgets(
    'expanded rail at expanded breakpoint does not overflow title bar',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(848, 768));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpApp(
        tester,
        home: DesktopShell(width: 848, height: 768, initialRailExtended: true),
      );

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('compact and medium select library from bottom navigation', (
    WidgetTester tester,
  ) async {
    Future<void> pumpAndSelectLibrary(double width) async {
      ShellNavigationSnapshot? lastSnapshot;

      await tester.binding.setSurfaceSize(Size(width, 768));
      await pumpApp(
        tester,
        home: DesktopShell(
          width: width,
          height: 768,
          paneBuilder: (_, navigation) {
            lastSnapshot = navigation;
            return Text('pane:${navigation.destinationIndex}');
          },
        ),
      );

      expect(find.byType(ExpressiveNavigationBar), findsOneWidget);
      await tester.tap(find.text('漫画库'));
      await tester.pumpAndSettle();

      expect(
        lastSnapshot?.destinationIndex,
        ShellNavigation.libraryDestinationIndex,
      );
      expect(
        find.text('pane:${ShellNavigation.libraryDestinationIndex}'),
        findsOneWidget,
      );
    }

    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpAndSelectLibrary(390);
    await pumpAndSelectLibrary(600);
  });

  testWidgets(
    'compact settings keeps bottom nav and back returns to previous destination',
    (WidgetTester tester) async {
      ShellNavigationSnapshot? lastSnapshot;

      await tester.binding.setSurfaceSize(const Size(390, 768));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pumpApp(
        tester,
        home: DesktopShell(
          width: 390,
          height: 768,
          paneBuilder: (_, navigation) {
            lastSnapshot = navigation;
            return Text('pane:${navigation.destinationIndex}');
          },
        ),
      );

      final int previousIndex = lastSnapshot!.destinationIndex;
      expect(find.byType(ExpressiveNavigationBar), findsOneWidget);

      await tester.tap(find.text('设置'));
      await tester.pumpAndSettle();

      expect(
        lastSnapshot?.destinationIndex,
        ShellNavigation.settingsDestinationIndex,
      );
      expect(find.byType(ExpressiveNavigationBar), findsOneWidget);
      expect(lastSnapshot?.onBackToPreviousDestination, isNotNull);

      lastSnapshot!.onBackToPreviousDestination!();
      await tester.pumpAndSettle();

      expect(lastSnapshot?.destinationIndex, previousIndex);
      expect(find.text('pane:$previousIndex'), findsOneWidget);
    },
  );

  testWidgets('expanded shell hover opens library flyout and selects library', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1024, 768));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const String targetId = 'lab-local-archive';
    final String targetName = LabLibraryCatalog.displayNameForId(targetId);
    ShellNavigationSnapshot? lastSnapshot;

    await pumpApp(
      tester,
      home: DesktopShell(
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
      ShellNavigation.libraryDestinationIndex,
    );
  });

  testWidgets('title bar window controls center in 36dp band', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1024, 768));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpApp(tester, home: DesktopShell(width: 1024, height: 768));
    await tester.pumpAndSettle();

    const double titleBandCenter = 18;
    expect(
      tester.getRect(find.byIcon(Icons.remove)).center.dy,
      titleBandCenter,
    );
    // 导航栏菜单仍位于 rail 顶部（非标题栏），保持 32dp 中心。
    expect(tester.getRect(find.byIcon(M3EIcons.menu)).center.dy, 32);
  });
}
