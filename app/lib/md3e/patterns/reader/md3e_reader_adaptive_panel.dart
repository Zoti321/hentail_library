import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/patterns/library/md3e_library_filter_sort_metrics.dart';
import 'package:hentai_library/md3e/theme/md3e_theme.dart';
import 'package:hentai_library/md3e/widgets/sheets/md3e_overlay_route_scope.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Lab 阅读器 secondary 面板：compact/medium 用 bottom sheet，expanded+ 用 side sheet。
abstract final class Md3eReaderAdaptivePanel {
  Md3eReaderAdaptivePanel._();

  static bool preferBottomSheet(double viewportWidth) {
    return viewportWidth < Md3eBreakpoints.expanded;
  }

  static M3ESideSheetTheme sideSheetTheme(M3EThemeData m3e) {
    return m3e.sideSheetTheme.copyWith(
      horizontalPadding: 16,
      topElementsGap: 8,
      headlineTextStyle: m3e.typeScale.titleLarge.copyWith(
        fontFamily: kMd3eAppFontFamily,
      ),
    );
  }

  static bool sideSheetDetachedFor(double viewportWidth) {
    return md3eLibraryFilterSortSideSheetDetachedForViewport(viewportWidth);
  }

  static double sideSheetWidthFor(double viewportWidth) {
    if (preferBottomSheet(viewportWidth)) {
      return viewportWidth;
    }
    return 400;
  }

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required Widget body,
    bool useRootNavigator = false,
  }) {
    final double viewportWidth = MediaQuery.sizeOf(context).width;
    final M3EThemeData m3e = M3ETheme.of(context);
    final Widget scopedBody = md3eOverlayRouteScope(
      anchorContext: context,
      child: body,
    );

    if (preferBottomSheet(viewportWidth)) {
      return M3EBottomSheet.show<T>(
        context,
        useRootNavigator: useRootNavigator,
        expandToFullScreen: true,
        fullScreenTitle: title,
        theme: m3e.bottomSheetTheme,
        builder: (BuildContext sheetContext) {
          return PrimaryScrollController.none(
            child: scopedBody,
          );
        },
      );
    }

    return M3ESideSheet.show<T>(
      context,
      title: title,
      width: sideSheetWidthFor(viewportWidth),
      detached: sideSheetDetachedFor(viewportWidth),
      theme: sideSheetTheme(m3e),
      scrollable: true,
      useRootNavigator: useRootNavigator,
      body: scopedBody,
    );
  }
}
