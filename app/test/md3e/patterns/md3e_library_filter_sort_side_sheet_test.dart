import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/patterns/library/md3e_library_filter_sort_metrics.dart';
import 'package:hentai_library/md3e/patterns/library/md3e_library_filter_sort_side_sheet.dart';
import 'package:hentai_library/shared/domain/library/library_age_restriction_filter.dart';
import 'package:hentai_library/shared/domain/library/library_comic_sort_option.dart';
import 'package:hentai_library/md3e/patterns/library/md3e_library_page_header.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../support/pump_md3e_app.dart';

void main() {
  group('Md3eLibraryFilterSortRowMetrics', () {
    test('compact rows are taller for touch targets', () {
      final Md3eLibraryFilterSortRowMetrics compact =
          Md3eLibraryFilterSortRowMetrics.forTier(
            Md3eLibraryFilterSortLayoutTier.compact,
          );
      final Md3eLibraryFilterSortRowMetrics expanded =
          Md3eLibraryFilterSortRowMetrics.forTier(
            Md3eLibraryFilterSortLayoutTier.expanded,
          );
      expect(compact.rowMinHeight, greaterThan(expanded.rowMinHeight));
      expect(compact.rowMinHeight, 48);
      expect(compact.checkboxTargetSize, compact.rowMinHeight);
      expect(expanded.checkboxTargetSize, expanded.rowMinHeight);
    });
  });

  group('md3eLibraryFilterSortSideSheetWidth', () {
    test('compact 390 is at least 260 for sheet title', () {
      expect(
        md3eLibraryFilterSortSideSheetWidthForViewport(
          Md3eBreakpoints.previewWidthCompact,
        ),
        260,
      );
    });
  });

  group('md3eLibraryFilterSortDrawerWidth', () {
    test('compact 390 matches design ~214', () {
      expect(
        md3eLibraryFilterSortDrawerWidthForViewport(
          Md3eBreakpoints.previewWidthCompact,
        ),
        closeTo(214, 1),
      );
    });

    test('medium and expanded tiers', () {
      expect(
        md3eLibraryFilterSortDrawerWidth(
          Md3eLibraryFilterSortLayoutTier.medium,
          800,
        ),
        280,
      );
      expect(
        md3eLibraryFilterSortDrawerWidth(
          Md3eLibraryFilterSortLayoutTier.expanded,
          1200,
        ),
        360,
      );
    });
  });

  group('md3eLibraryFilterSortSideSheetDetached', () {
    test('enabled from expanded breakpoint (840+)', () {
      expect(
        md3eLibraryFilterSortSideSheetDetachedForViewport(
          Md3eBreakpoints.previewWidthMedium,
        ),
        isFalse,
      );
      expect(
        md3eLibraryFilterSortSideSheetDetachedForViewport(
          Md3eBreakpoints.expanded - 1,
        ),
        isFalse,
      );
      expect(
        md3eLibraryFilterSortSideSheetDetachedForViewport(
          Md3eBreakpoints.expanded,
        ),
        isTrue,
      );
      expect(
        md3eLibraryFilterSortSideSheetDetachedForViewport(
          Md3eBreakpoints.previewWidthExpanded,
        ),
        isTrue,
      );
    });
  });

  group('Md3eLibraryFilterSortState', () {
    test('isCustomized reflects non-default filters and sort', () {
      expect(Md3eLibraryFilterSortState.defaults.isCustomized, isFalse);
      expect(
        Md3eLibraryFilterSortState.defaults
            .toggleAgeRestriction(LibraryAgeRestrictionFilter.allAges)
            .isCustomized,
        isTrue,
      );
      expect(
        Md3eLibraryFilterSortState.defaults
            .selectSortField(LibraryComicSortField.createdAt)
            .isCustomized,
        isTrue,
      );
    });
  });

  group('md3eLibraryFilterSortPrefersBottomSheet', () {
    test('compact and medium use bottom sheet, expanded+ uses side sheet', () {
      expect(
        md3eLibraryFilterSortPrefersBottomSheetForViewport(
          Md3eBreakpoints.previewWidthCompact,
        ),
        isTrue,
      );
      expect(
        md3eLibraryFilterSortPrefersBottomSheetForViewport(
          Md3eBreakpoints.expanded - 1,
        ),
        isTrue,
      );
      expect(
        md3eLibraryFilterSortPrefersBottomSheetForViewport(
          Md3eBreakpoints.expanded,
        ),
        isFalse,
      );
      expect(
        md3eLibraryFilterSortPrefersBottomSheetForViewport(
          Md3eBreakpoints.previewWidthExpanded,
        ),
        isFalse,
      );
    });
  });

  testWidgets('compact header opens bottom sheet and shows filter sections', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpMd3eApp(
      tester,
      home: Center(
        child: SizedBox(
          width: Md3eBreakpoints.previewWidthCompact,
          child: Md3eLibraryFilterSortDrawerHost(
            body: Builder(
              builder: (BuildContext context) {
                return Md3eLibraryPageHeader(
                  onFilterSort: () =>
                      Md3eLibraryFilterSortDrawerHost.openDrawer(context),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.filter_list));
    await tester.pumpAndSettle();

    expect(find.byType(M3ESideSheet), findsNothing);
    expect(find.text('排序'), findsOneWidget);
    expect(find.text('年龄限制'), findsOneWidget);
  });

  testWidgets('expanded header opens side sheet and shows filter sections', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpMd3eApp(
      tester,
      home: Center(
        child: SizedBox(
          width: Md3eBreakpoints.previewWidthExpanded,
          child: Md3eLibraryFilterSortDrawerHost(
            body: Builder(
              builder: (BuildContext context) {
                return Md3eLibraryPageHeader(
                  onFilterSort: () =>
                      Md3eLibraryFilterSortDrawerHost.openDrawer(context),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.filter_list));
    await tester.pumpAndSettle();

    expect(find.text('筛选与排序'), findsOneWidget);
    expect(find.text('年龄限制'), findsOneWidget);
  });

  testWidgets('customized filter highlights header filter action', (
    WidgetTester tester,
  ) async {
    final Md3eLibraryFilterSortState customized = Md3eLibraryFilterSortState
        .defaults
        .toggleAgeRestriction(LibraryAgeRestrictionFilter.r18Only);

    await pumpMd3eApp(
      tester,
      home: Center(
        child: SizedBox(
          width: Md3eBreakpoints.previewWidthExpanded,
          child: Md3eLibraryFilterSortDrawerHost(
            initialState: customized,
            body: Md3eLibraryPageHeader(
              filterSortActive: customized.isCustomized,
            ),
          ),
        ),
      ),
    );

    final Icon filterIcon = tester.widget<Icon>(find.byIcon(Icons.filter_list));
    expect(filterIcon.color, isNotNull);
  });
}
