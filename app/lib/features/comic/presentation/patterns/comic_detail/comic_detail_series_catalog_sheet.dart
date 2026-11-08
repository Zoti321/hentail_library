import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:hentai_library/shared/ui/patterns/library/library_filter_sort_metrics.dart';
import 'package:hentai_library/shared/ui/theme/app_m3e_theme.dart';
import 'package:hentai_library/shared/ui/widgets/sheets/overlay_route_scope.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// 漫画详情「系列目录」：medium- bottom sheet；expanded+ detached side sheet。
abstract final class ComicDetailSeriesCatalogSheet {
  ComicDetailSeriesCatalogSheet._();

  static bool preferBottomSheet(double viewportWidth) {
    return viewportWidth < Breakpoints.expanded;
  }

  static Widget _catalogBody({
    required BuildContext sheetContext,
    required M3EThemeData m3e,
    required OverlayRouteScopeSnapshot scope,
    required List<String> catalog,
    required int currentIndex,
    required ValueChanged<int> onSelectIndex,
  }) {
    final double itemGap = m3e.menuTheme.itemGap;
    return overlayRouteScope(
      scope: scope,
      child: M3ETheme(
        data: m3e,
        child: ListView.separated(
          padding: EdgeInsets.fromLTRB(
            m3e.spacing.md,
            m3e.spacing.sm,
            m3e.spacing.md,
            m3e.spacing.lg,
          ),
          itemCount: catalog.length,
          separatorBuilder: (BuildContext context, int index) {
            return itemGap > 0
                ? SizedBox(height: itemGap)
                : const SizedBox.shrink();
          },
          itemBuilder: (BuildContext context, int index) {
            return M3EMenuItem(
              label: catalog[index],
              leading: const Icon(Symbols.menu_book),
              selected: index == currentIndex,
              onTap: () {
                onSelectIndex(index);
                Navigator.of(sheetContext).maybePop();
              },
            );
          },
        ),
      ),
    );
  }

  static Future<void> show(
    BuildContext context, {
    required List<String> catalog,
    required int currentIndex,
    required ValueChanged<int> onSelectIndex,
  }) {
    final double viewportWidth = MediaQuery.sizeOf(context).width;
    final OverlayRouteScopeSnapshot scope = OverlayRouteScopeSnapshot.capture(
      context,
    );
    final M3EThemeData m3e = withAppFontFamily(M3ETheme.of(context));
    final String title = context.l10n.comicDetailSeriesCatalog;

    if (preferBottomSheet(viewportWidth)) {
      return M3EBottomSheet.show<void>(
        context,
        initialValue: M3EBottomSheetValue.collapsed,
        theme: m3e.bottomSheetTheme,
        builder: (BuildContext sheetContext) {
          return _catalogBody(
            sheetContext: sheetContext,
            m3e: m3e,
            scope: scope,
            catalog: catalog,
            currentIndex: currentIndex,
            onSelectIndex: onSelectIndex,
          );
        },
      );
    }

    // 列表自行滚动；避免 SideSheet scrollable + 内部 ListView 双重约束冲突。
    return M3ESideSheet.show<void>(
      context,
      title: title,
      width: libraryFilterSortSideSheetWidthForViewport(viewportWidth),
      detached: true,
      theme: libraryFilterSortSideSheetTheme(m3e),
      scrollable: false,
      body: Builder(
        builder: (BuildContext sheetContext) {
          return _catalogBody(
            sheetContext: sheetContext,
            m3e: m3e,
            scope: scope,
            catalog: catalog,
            currentIndex: currentIndex,
            onSelectIndex: onSelectIndex,
          );
        },
      ),
    );
  }
}
