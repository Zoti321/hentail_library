import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/library_page_facade_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/views/library_md3e/library_md3e_filter_section.dart';
import 'package:hentai_library/features/library_browse/presentation/views/library_md3e/library_md3e_sort_section.dart';
import 'package:hentai_library/md3e/patterns/library/md3e_library_filter_sort_metrics.dart';
import 'package:hentai_library/md3e/theme/md3e_theme.dart';
import 'package:hentai_library/md3e/widgets/sheets/md3e_overlay_route_scope.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 库页筛选排序面板（MD3E）：compact / medium 为底部 sheet（全屏展开），expanded+ 为侧边 sheet。
///
/// 即时生效，无底部「应用」按钮；正文为 [Md3eLibraryFilterSortContent]。
abstract final class Md3eLibraryFilterSortSheet {
  Md3eLibraryFilterSortSheet._();

  static Future<void> show(BuildContext context) {
    final double viewportWidth = MediaQuery.sizeOf(context).width;
    final String title = AppLocalizations.of(context).libraryFilterSortTooltip;
    final Md3eOverlayRouteScopeSnapshot scope =
        Md3eOverlayRouteScopeSnapshot.capture(context);
    final M3EThemeData m3e = md3eWithAppFontFamily(M3ETheme.of(context));
    final Widget body = md3eOverlayRouteScope(
      scope: scope,
      child: M3ETheme(data: m3e, child: const Md3eLibraryFilterSortContent()),
    );

    if (md3eLibraryFilterSortPrefersBottomSheetForViewport(viewportWidth)) {
      return M3EBottomSheet.show<void>(
        context,
        useRootNavigator: true,
        expandToFullScreen: true,
        fullScreenTitle: title,
        theme: M3ETheme.of(context).bottomSheetTheme,
        builder: (BuildContext sheetContext) {
          return PrimaryScrollController.none(
            child: SingleChildScrollView(child: body),
          );
        },
      );
    }

    return M3ESideSheet.show<void>(
      context,
      title: title,
      width: md3eLibraryFilterSortSideSheetWidthForViewport(viewportWidth),
      detached: md3eLibraryFilterSortSideSheetDetachedForViewport(
        viewportWidth,
      ),
      // 侧栏标题由 sheet 自身上下文读取主题，需显式指定应用字体。
      theme: M3ETheme.of(context).sideSheetTheme.copyWith(
        horizontalPadding: 16,
        topElementsGap: 8,
        headlineTextStyle: const TextStyle(fontFamily: kMd3eAppFontFamily),
      ),
      scrollable: true,
      useRootNavigator: true,
      body: body,
    );
  }
}

/// 筛选排序面板正文：重置按钮 + 筛选区 + 排序区（不含外层滚动与 Drawer 外壳）。
class Md3eLibraryFilterSortContent extends ConsumerWidget {
  const Md3eLibraryFilterSortContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool isCustomized = ref.watch(
      libraryPageFacadeProvider.select(
        (LibraryPageFacadeState state) => state.isFilterSortCustomized,
      ),
    );
    final AppLocalizations l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: kLibraryMd3eSortSectionInset,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    l10n.libraryFilterSection,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
                // 始终占位、无变化时禁用，避免出现/消失造成布局抖动。
                TextButton(
                  onPressed: isCustomized
                      ? () => ref
                            .read(libraryPageFacadeProvider.notifier)
                            .resetFilters()
                      : null,
                  child: Text(
                    l10n.libraryResetAllFilters,
                    style: TextStyle(fontSize: 12, color: cs.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Md3eLibraryFilterSection(),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.only(left: kLibraryMd3eSortSectionInset),
            child: Text(
              l10n.librarySortSection,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Md3eLibrarySortSection(),
        ],
      ),
    );
  }
}
