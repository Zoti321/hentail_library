import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/patterns/md3e_desktop_shell.dart';
import 'package:hentai_library/md3e/widgets/desktop/md3e_desktop_title_bar.dart';
import 'package:hentai_library/md3e/widgets/desktop/md3e_navigation_rail.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../support/pump_md3e_app.dart';

void main() {
  testWidgets('Md3eDesktopShell places rail menu beside title bar row', (
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

  testWidgets('title bar search leading inset is flush with pane column', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1024, 768));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpMd3eApp(
      tester,
      home: Md3eDesktopShell(width: 1024, height: 768),
    );

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

    await pumpMd3eApp(
      tester,
      home: Md3eDesktopShell(width: 1024, height: 768),
    );
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

  testWidgets('expanded rail at expanded breakpoint does not overflow title bar', (
    WidgetTester tester,
  ) async {
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
  });

  testWidgets('title band icons share vertical center at 32dp', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1024, 768));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpMd3eApp(
      tester,
      home: Md3eDesktopShell(width: 1024, height: 768),
    );
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
