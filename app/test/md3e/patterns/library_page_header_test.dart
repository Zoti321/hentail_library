import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/patterns/library/library_display_target_tabs.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/patterns/library/library_page_header.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:hentai_library/shared/ui/patterns/library/library_page_header_metrics.dart';

import '../../support/pump_app.dart';

void main() {
  testWidgets('expanded shows title and actions only (no inline tabs)', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      home: Center(
        child: SizedBox(
          width: Breakpoints.previewWidthExpanded,
          child: LibraryPageHeader(onFilterSort: () {}),
        ),
      ),
    );

    expect(
      LibraryPageHeaderMetrics.layoutFor(WindowSizeClass.expanded),
      LibraryPageHeaderLayout.titleAndActionsOnly,
    );
    expect(find.text('漫画库'), findsOneWidget);
    expect(find.byType(LibraryDisplayTargetTabs), findsNothing);
    expect(find.byType(M3ETabs), findsNothing);
  });

  testWidgets('large uses title row without display target tabs', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      home: Center(
        child: SizedBox(
          width: Breakpoints.previewWidthLarge,
          child: const LibraryPageHeader(),
        ),
      ),
    );

    expect(
      LibraryPageHeaderMetrics.layoutFor(WindowSizeClass.large),
      LibraryPageHeaderLayout.titleAndActionsOnly,
    );
    expect(find.byType(LibraryDisplayTargetTabs), findsNothing);
  });

  testWidgets('medium uses window width for title typography', (
    WidgetTester tester,
  ) async {
    const double windowWidth = Breakpoints.previewWidthMedium;
    final double horizontal = PageLayoutSpec.resolve(
      const LayoutContext(
        viewportWidth: windowWidth,
        inputMode: LayoutInputMode.touch,
      ),
    ).horizontalInset;
    final double contentWidth = windowWidth - horizontal * 2;

    await pumpApp(
      tester,
      home: MediaQuery(
        data: MediaQueryData(size: Size(windowWidth, 800)),
        child: Center(
          child: SizedBox(
            width: contentWidth,
            child: const LibraryPageHeader(),
          ),
        ),
      ),
    );

    expect(
      LibraryPageHeaderMetrics.layoutFor(WindowSizeClass.medium),
      LibraryPageHeaderLayout.titleAndActionsOnly,
    );
    expect(find.text('漫画库'), findsOneWidget);
  });

  testWidgets('compact shows filter and overflow actions', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      home: Center(
        child: SizedBox(
          width: Breakpoints.previewWidthCompact,
          child: LibraryPageHeader(
            filterSortActive: true,
            pageSize: 50,
            onPageSizeChanged: (_) {},
            overflowMenuEntries: const <M3EMenuEntry>[
              M3EMenuEntry(label: '刷新目录'),
            ],
            onFilterSort: () {},
          ),
        ),
      ),
    );

    expect(
      LibraryPageHeaderMetrics.layoutFor(WindowSizeClass.compact),
      LibraryPageHeaderLayout.titleAndActionsOnly,
    );
    expect(find.byIcon(Icons.filter_list), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
  });
}
