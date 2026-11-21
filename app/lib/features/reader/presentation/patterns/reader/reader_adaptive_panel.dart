import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Lab 阅读器 secondary 面板：compact/medium 用 bottom sheet，expanded+ 用 side sheet。
abstract final class ReaderAdaptivePanel {
  ReaderAdaptivePanel._();

  static bool preferBottomSheet(double viewportWidth) {
    return viewportWidth < Breakpoints.expanded;
  }

  static M3ESideSheetTheme sideSheetTheme(M3EThemeData m3e) {
    return m3e.sideSheetTheme.copyWith(
      horizontalPadding: 16,
      topElementsGap: 8,
      headlineTextStyle: m3e.typeScale.titleLarge.copyWith(
        fontFamily: m3e.typeScale.bodyLarge.fontFamily ?? kAppFontFamily,
      ),
    );
  }

  static bool sideSheetDetachedFor(double viewportWidth) {
    return libraryFilterSortSideSheetDetachedForViewport(viewportWidth);
  }

  static double sideSheetWidthFor(double viewportWidth) {
    if (preferBottomSheet(viewportWidth)) {
      return viewportWidth;
    }
    return 400;
  }

  /// [expandToFullScreen] / [showCloseButton] 控制标题栏 chrome；阅读设置可关掉。
  /// [scrollable] 为 false 时由 [body] 自行滚动（如内部 [ListView]）。
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required Widget body,
    bool useRootNavigator = false,
    bool expandToFullScreen = true,
    bool showCloseButton = true,
    bool scrollable = true,
  }) {
    final double viewportWidth = MediaQuery.sizeOf(context).width;
    final M3EThemeData m3e = M3ETheme.of(context);
    final Widget scopedBody = OverlayRouteScope(
      scope: OverlayRouteScopeSnapshot.capture(context),
      child: body,
    );

    if (preferBottomSheet(viewportWidth)) {
      return M3EBottomSheet.show<T>(
        context,
        useRootNavigator: useRootNavigator,
        expandToFullScreen: expandToFullScreen,
        fullScreenTitle: expandToFullScreen ? title : null,
        theme: m3e.bottomSheetTheme,
        builder: (BuildContext sheetContext) {
          return PrimaryScrollController.none(child: scopedBody);
        },
      );
    }

    return M3ESideSheet.show<T>(
      context,
      title: title,
      showCloseButton: showCloseButton,
      width: sideSheetWidthFor(viewportWidth),
      detached: sideSheetDetachedFor(viewportWidth),
      theme: sideSheetTheme(m3e),
      scrollable: scrollable,
      useRootNavigator: useRootNavigator,
      body: scopedBody,
    );
  }
}
