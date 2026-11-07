import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_page_facade_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/views/library/library_filter_section.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/views/library/library_grouping_section.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/views/library/library_sort_section.dart';
import 'package:hentai_library/shared/ui/patterns/library/library_filter_sort_metrics.dart';
import 'package:hentai_library/shared/ui/theme/app_m3e_theme.dart';
import 'package:hentai_library/shared/ui/widgets/sheets/overlay_route_scope.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// 库页筛选排序面板（MD3E）：compact / medium 为底部 sheet（全屏展开），expanded+ 为侧边 sheet。
///
/// 即时生效，无底部「应用」按钮；正文为 [LibraryFilterSortContent]。
abstract final class LibraryFilterSortSheet {
  LibraryFilterSortSheet._();

  static Future<void> show(BuildContext context) {
    final double viewportWidth = MediaQuery.sizeOf(context).width;
    final OverlayRouteScopeSnapshot scope = OverlayRouteScopeSnapshot.capture(
      context,
    );
    final M3EThemeData m3e = withAppFontFamily(M3ETheme.of(context));
    final Widget body = overlayRouteScope(
      scope: scope,
      child: M3ETheme(data: m3e, child: const LibraryFilterSortContent()),
    );

    if (libraryFilterSortPrefersBottomSheetForViewport(viewportWidth)) {
      return M3EBottomSheet.show<void>(
        context,
        useRootNavigator: true,
        expandToFullScreen: true,
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
      title: '',
      width: libraryFilterSortSideSheetWidthForViewport(viewportWidth),
      detached: libraryFilterSortSideSheetDetachedForViewport(viewportWidth),
      // 侧栏标题由 sheet 自身上下文读取主题，需显式指定应用字体。
      theme: M3ETheme.of(context).sideSheetTheme.copyWith(
        horizontalPadding: 16,
        topElementsGap: 8,
        headlineTextStyle: TextStyle(fontFamily: appFontFamilyOf(context)),
      ),
      scrollable: true,
      useRootNavigator: true,
      body: body,
    );
  }
}

/// 筛选排序面板正文：重置按钮 + 筛选 / 分组 / 排序三区（不含外层滚动与 Drawer 外壳）。
class LibraryFilterSortContent extends ConsumerWidget {
  const LibraryFilterSortContent({super.key});

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
              horizontal: kLibrarySortSectionInset,
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
                M3EIconButton(
                  icon: const Icon(Symbols.settings_backup_restore, size: 20),
                  tooltip: l10n.libraryResetAllFilters,
                  semanticLabel: l10n.libraryResetAllFilters,
                  onPressed: isCustomized
                      ? () => ref
                            .read(libraryPageFacadeProvider.notifier)
                            .resetFilters()
                      : null,
                  variant: M3EIconButtonVariant.standard,
                  size: M3EIconButtonSize.sm,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const LibraryFilterSection(),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.only(left: kLibrarySortSectionInset),
            child: Text(
              l10n.libraryGroupSection,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const LibraryGroupingSection(),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.only(left: kLibrarySortSectionInset),
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
          const LibrarySortSection(),
        ],
      ),
    );
  }
}
