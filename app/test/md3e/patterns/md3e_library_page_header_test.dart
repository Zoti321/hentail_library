import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/patterns/md3e_library_display_target_tabs.dart';
import 'package:hentai_library/md3e/patterns/md3e_library_page_header.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:hentai_library/md3e/patterns/md3e_library_page_header_metrics.dart';

import '../../support/pump_md3e_app.dart';

void main() {
  testWidgets('expanded shows title and actions only (no inline tabs)', (
    WidgetTester tester,
  ) async {
    await pumpMd3eApp(
      tester,
      home: Center(
        child: SizedBox(
          width: Md3eBreakpoints.previewWidthExpanded,
          child: Md3eLibraryPageHeader(
            onFilterSort: () {},
          ),
        ),
      ),
    );

    expect(
      Md3eLibraryPageHeaderMetrics.layoutFor(
        Md3eWindowSizeClass.expanded,
      ),
      Md3eLibraryPageHeaderLayout.titleAndActionsOnly,
    );
    expect(find.text('漫画库'), findsOneWidget);
    expect(find.byType(Md3eLibraryDisplayTargetTabs), findsNothing);
    expect(find.byType(M3ETabs), findsNothing);
  });

  testWidgets('large uses title row without display target tabs', (
    WidgetTester tester,
  ) async {
    await pumpMd3eApp(
      tester,
      home: Center(
        child: SizedBox(
          width: Md3eBreakpoints.previewWidthLarge,
          child: const Md3eLibraryPageHeader(),
        ),
      ),
    );

    expect(
      Md3eLibraryPageHeaderMetrics.layoutFor(Md3eWindowSizeClass.large),
      Md3eLibraryPageHeaderLayout.titleAndActionsOnly,
    );
    expect(find.byType(Md3eLibraryDisplayTargetTabs), findsNothing);
  });

  testWidgets('medium uses window width for title typography', (
    WidgetTester tester,
  ) async {
    const double windowWidth = Md3eBreakpoints.previewWidthMedium;
    final double horizontal =
        Md3eLibraryPageHeaderMetrics.contentHorizontalPadding(
          Md3eWindowSizeClass.medium,
        );
    final double contentWidth = windowWidth - horizontal * 2;

    await pumpMd3eApp(
      tester,
      home: MediaQuery(
        data: MediaQueryData(size: Size(windowWidth, 800)),
        child: Center(
          child: SizedBox(
            width: contentWidth,
            child: const Md3eLibraryPageHeader(),
          ),
        ),
      ),
    );

    expect(
      Md3eLibraryPageHeaderMetrics.layoutFor(Md3eWindowSizeClass.medium),
      Md3eLibraryPageHeaderLayout.titleAndActionsOnly,
    );
    expect(find.text('漫画库'), findsOneWidget);
  });

  testWidgets('compact shows filter and overflow actions', (
    WidgetTester tester,
  ) async {
    await pumpMd3eApp(
      tester,
      home: Center(
        child: SizedBox(
          width: Md3eBreakpoints.previewWidthCompact,
          child: Md3eLibraryPageHeader(
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
      Md3eLibraryPageHeaderMetrics.layoutFor(Md3eWindowSizeClass.compact),
      Md3eLibraryPageHeaderLayout.titleAndActionsOnly,
    );
    expect(find.byIcon(Icons.filter_list), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
  });
}
