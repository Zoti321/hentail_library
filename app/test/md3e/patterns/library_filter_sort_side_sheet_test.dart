import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:hentai_library/shared/ui/patterns/library/library_filter_sort_metrics.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/patterns/library/library_filter_sort_side_sheet.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_age_restriction_filter.dart';
import 'package:hentai_library/features/comic/domain/library_comic_sort_option.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/patterns/library/library_page_header.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../support/pump_app.dart';

void main() {
  group('LibraryFilterSortRowMetrics', () {
    test('compact rows are taller for touch targets', () {
      final LibraryFilterSortRowMetrics compact =
          LibraryFilterSortRowMetrics.forTier(
            LibraryFilterSortLayoutTier.compact,
          );
      final LibraryFilterSortRowMetrics expanded =
          LibraryFilterSortRowMetrics.forTier(
            LibraryFilterSortLayoutTier.expanded,
          );
      expect(compact.rowMinHeight, greaterThan(expanded.rowMinHeight));
      expect(compact.rowMinHeight, 48);
      expect(compact.checkboxTargetSize, compact.rowMinHeight);
      expect(expanded.checkboxTargetSize, expanded.rowMinHeight);
    });
  });

  group('libraryFilterSortSideSheetWidth', () {
    test('compact 390 is at least 260 for sheet title', () {
      expect(
        libraryFilterSortSideSheetWidthForViewport(
          Breakpoints.previewWidthCompact,
        ),
        260,
      );
    });
  });

  group('libraryFilterSortDrawerWidth', () {
    test('compact 390 matches design ~214', () {
      expect(
        libraryFilterSortDrawerWidthForViewport(
          Breakpoints.previewWidthCompact,
        ),
        closeTo(214, 1),
      );
    });

    test('medium and expanded tiers', () {
      expect(
        libraryFilterSortDrawerWidth(LibraryFilterSortLayoutTier.medium, 800),
        280,
      );
      expect(
        libraryFilterSortDrawerWidth(
          LibraryFilterSortLayoutTier.expanded,
          1200,
        ),
        360,
      );
    });
  });

  group('libraryFilterSortSideSheetDetached', () {
    test('enabled from expanded breakpoint (840+)', () {
      expect(
        libraryFilterSortSideSheetDetachedForViewport(
          Breakpoints.previewWidthMedium,
        ),
        isFalse,
      );
      expect(
        libraryFilterSortSideSheetDetachedForViewport(Breakpoints.expanded - 1),
        isFalse,
      );
      expect(
        libraryFilterSortSideSheetDetachedForViewport(Breakpoints.expanded),
        isTrue,
      );
      expect(
        libraryFilterSortSideSheetDetachedForViewport(
          Breakpoints.previewWidthExpanded,
        ),
        isTrue,
      );
    });
  });

  group('LibraryFilterSortState', () {
    test('isCustomized reflects non-default filters and sort', () {
      expect(LibraryFilterSortState.defaults.isCustomized, isFalse);
      expect(
        LibraryFilterSortState.defaults
            .toggleAgeRestriction(LibraryAgeRestrictionFilter.allAges)
            .isCustomized,
        isTrue,
      );
      expect(
        LibraryFilterSortState.defaults
            .selectSortField(LibraryComicSortField.createdAt)
            .isCustomized,
        isTrue,
      );
    });
  });

  group('libraryFilterSortPrefersBottomSheet', () {
    test('compact and medium use bottom sheet, expanded+ uses side sheet', () {
      expect(
        libraryFilterSortPrefersBottomSheetForViewport(
          Breakpoints.previewWidthCompact,
        ),
        isTrue,
      );
      expect(
        libraryFilterSortPrefersBottomSheetForViewport(
          Breakpoints.expanded - 1,
        ),
        isTrue,
      );
      expect(
        libraryFilterSortPrefersBottomSheetForViewport(Breakpoints.expanded),
        isFalse,
      );
      expect(
        libraryFilterSortPrefersBottomSheetForViewport(
          Breakpoints.previewWidthExpanded,
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

    await pumpApp(
      tester,
      home: Center(
        child: SizedBox(
          width: Breakpoints.previewWidthCompact,
          child: LibraryFilterSortDrawerHost(
            body: Builder(
              builder: (BuildContext context) {
                return LibraryPageHeader(
                  onFilterSort: () =>
                      LibraryFilterSortDrawerHost.openDrawer(context),
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
    await pumpApp(
      tester,
      home: Center(
        child: SizedBox(
          width: Breakpoints.previewWidthExpanded,
          child: LibraryFilterSortDrawerHost(
            body: Builder(
              builder: (BuildContext context) {
                return LibraryPageHeader(
                  onFilterSort: () =>
                      LibraryFilterSortDrawerHost.openDrawer(context),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.filter_list));
    await tester.pumpAndSettle();

    expect(find.text('排序'), findsOneWidget);
    expect(find.text('年龄限制'), findsOneWidget);
  });

  testWidgets('折叠分组箭头用弹簧旋转：中间帧介于起止角度之间，结束后到达 180°', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpApp(
      tester,
      home: Center(
        child: SizedBox(
          width: Breakpoints.previewWidthExpanded,
          child: LibraryFilterSortDrawerHost(
            body: Builder(
              builder: (BuildContext context) {
                return LibraryPageHeader(
                  onFilterSort: () =>
                      LibraryFilterSortDrawerHost.openDrawer(context),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.filter_list));
    await tester.pumpAndSettle();

    final Finder header = find.ancestor(
      of: find.text('年龄限制'),
      matching: find.byType(InkWell),
    );
    final Finder arrow = find.descendant(
      of: header.first,
      matching: find.byIcon(Icons.keyboard_arrow_down),
    );
    // 取箭头最近的 Transform（旋转所在层）。
    double angle() {
      Transform? nearest;
      tester.element(arrow).visitAncestorElements((Element element) {
        if (element.widget is Transform) {
          nearest = element.widget as Transform;
          return false;
        }
        return true;
      });
      return nearest!.transform.storage[0];
    }

    await tester.tap(find.text('年龄限制'));
    final List<double> samples = <double>[];
    for (int i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      samples.add(angle());
    }
    // 弹簧过程中至少有一帧处于起止之间（不是瞬间切换）。
    expect(samples.any((double c) => c > -0.999 && c < 0.999), isTrue);

    await tester.pumpAndSettle();
    expect(angle(), closeTo(-1.0, 1e-3));
  });

  testWidgets('customized filter highlights header filter action', (
    WidgetTester tester,
  ) async {
    final LibraryFilterSortState customized = LibraryFilterSortState.defaults
        .toggleAgeRestriction(LibraryAgeRestrictionFilter.r18Only);

    await pumpApp(
      tester,
      home: Center(
        child: SizedBox(
          width: Breakpoints.previewWidthExpanded,
          child: LibraryFilterSortDrawerHost(
            initialState: customized,
            body: LibraryPageHeader(filterSortActive: customized.isCustomized),
          ),
        ),
      ),
    );

    final Icon filterIcon = tester.widget<Icon>(find.byIcon(Icons.filter_list));
    expect(filterIcon.color, isNotNull);
  });
}
