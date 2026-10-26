import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/patterns/md3e_library_display_target_tabs.dart';
import 'package:hentai_library/md3e/patterns/md3e_library_page_header.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:hentai_library/md3e/patterns/md3e_library_page_header_metrics.dart';

import '../../support/pump_md3e_app.dart';

void main() {
  testWidgets('expanded uses single row with centered tabs', (
    WidgetTester tester,
  ) async {
    await pumpMd3eApp(
      tester,
      home: Center(
        child: SizedBox(
          width: Md3eBreakpoints.previewWidthExpanded,
          child: Md3eLibraryPageHeader(
            displayTarget: Md3eLibraryDisplayTarget.comics,
            onDisplayTargetChanged: (_) {},
          ),
        ),
      ),
    );

    expect(
      Md3eLibraryPageHeaderMetrics.layoutFor(
        Md3eWindowSizeClass.expanded,
      ),
      Md3eLibraryPageHeaderLayout.singleRowWithTabs,
    );
    expect(find.text('漫画库'), findsOneWidget);
    expect(find.byType(Md3eLibraryDisplayTargetTabs), findsOneWidget);
    expect(find.byType(M3ETabs), findsOneWidget);
  });

  testWidgets('large uses single toolbar row with inline tabs', (
    WidgetTester tester,
  ) async {
    await pumpMd3eApp(
      tester,
      home: Center(
        child: SizedBox(
          width: Md3eBreakpoints.previewWidthLarge,
          child: Md3eLibraryPageHeader(
            displayTarget: Md3eLibraryDisplayTarget.comics,
            onDisplayTargetChanged: (_) {},
          ),
        ),
      ),
    );

    expect(
      Md3eLibraryPageHeaderMetrics.layoutFor(Md3eWindowSizeClass.large),
      Md3eLibraryPageHeaderLayout.singleRowWithTabs,
    );
    expect(find.byType(Md3eLibraryDisplayTargetTabs), findsOneWidget);
    expect(find.byType(M3ETabs), findsOneWidget);
  });

  testWidgets('medium uses single row with centered tabs', (
    WidgetTester tester,
  ) async {
    await pumpMd3eApp(
      tester,
      home: Center(
        child: SizedBox(
          width: Md3eBreakpoints.previewWidthMedium,
          child: Md3eLibraryPageHeader(
            displayTarget: Md3eLibraryDisplayTarget.comics,
            onDisplayTargetChanged: (_) {},
          ),
        ),
      ),
    );

    expect(
      Md3eLibraryPageHeaderMetrics.layoutFor(Md3eWindowSizeClass.medium),
      Md3eLibraryPageHeaderLayout.singleRowWithTabs,
    );
    expect(find.byType(Md3eLibraryDisplayTargetTabs), findsOneWidget);
    expect(find.byType(M3ETabs), findsOneWidget);
  });

  testWidgets('medium layout uses window width not padded content width', (
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
            child: Md3eLibraryPageHeader(
              displayTarget: Md3eLibraryDisplayTarget.comics,
              onDisplayTargetChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(
      Md3eLibraryPageHeaderMetrics.layoutFor(Md3eWindowSizeClass.medium),
      Md3eLibraryPageHeaderLayout.singleRowWithTabs,
    );
    expect(find.byType(Md3eLibraryDisplayTargetTabs), findsOneWidget);
  });

  testWidgets('compact uses single row with centered tabs', (
    WidgetTester tester,
  ) async {
    await pumpMd3eApp(
      tester,
      home: Center(
        child: SizedBox(
          width: Md3eBreakpoints.previewWidthCompact,
          child: Md3eLibraryPageHeader(
            displayTarget: Md3eLibraryDisplayTarget.comics,
            filterSortActive: true,
            pageSize: 50,
            onPageSizeChanged: (_) {},
            overflowMenuEntries: const <M3EMenuEntry>[
              M3EMenuEntry(label: '刷新目录'),
            ],
            onDisplayTargetChanged: (_) {},
            onFilterSort: () {},
          ),
        ),
      ),
    );

    expect(
      Md3eLibraryPageHeaderMetrics.layoutFor(Md3eWindowSizeClass.compact),
      Md3eLibraryPageHeaderLayout.singleRowWithTabs,
    );
    expect(find.byType(Md3eLibraryDisplayTargetTabs), findsOneWidget);
    expect(find.byType(M3ETabs), findsOneWidget);
    final M3ETabTheme tabTheme =
        Md3eLibraryPageHeaderMetrics.displayTargetTabThemeFor(
          Md3eWindowSizeClass.compact,
        );
    expect(tabTheme.dividerHeight, 0);
    expect(tabTheme.indicatorInset, -2);
  });
}
