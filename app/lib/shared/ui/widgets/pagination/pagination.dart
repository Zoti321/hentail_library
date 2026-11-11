import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/shared/ui/widgets/pagination/pagination_compact.dart';
import 'package:hentai_library/shared/ui/widgets/pagination/pagination_metrics.dart';
import 'package:hentai_library/shared/ui/widgets/pagination/pagination_standard.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Responsive MD3E pagination (Lab only; production uses [LibraryPaginationBar]).
///
/// Compact vs standard follows **window** width ([MediaQuery.sizeOf]), same as
/// [LibraryPageHeader] breakpoints—not the parent’s shrink-wrapped width.
class Pagination extends StatelessWidget {
  const Pagination({
    super.key,
    required this.page,
    required this.totalPages,
    required this.onPageChanged,
    this.totalItems,
    this.pageSize,
    this.enabled = true,
  });

  /// Current page, 1-based.
  final int page;

  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final int? totalItems;
  final int? pageSize;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) {
      return const SizedBox.shrink();
    }
    final int clampedPage = page.clamp(1, totalPages);
    final double windowWidth = MediaQuery.sizeOf(context).width;
    final WindowSizeClass sizeClass = WindowSizeClass.fromWidth(windowWidth);
    final bool useCompact =
        sizeClass.isCompact ||
        windowWidth < PaginationMetrics.standardBarMinWidth(sizeClass);

    if (useCompact) {
      return PaginationCompact(
        page: clampedPage,
        totalPages: totalPages,
        enabled: enabled,
        onPageChanged: onPageChanged,
        onOpenPagePicker: () => _showCompactPagePicker(
          context: context,
          page: clampedPage,
          totalPages: totalPages,
          onPageChanged: onPageChanged,
        ),
      );
    }

    return PaginationStandard(
      page: clampedPage,
      totalPages: totalPages,
      enabled: enabled,
      sizeClass: sizeClass,
      onPageChanged: onPageChanged,
    );
  }

  static Future<void> _showCompactPagePicker({
    required BuildContext context,
    required int page,
    required int totalPages,
    required ValueChanged<int> onPageChanged,
  }) async {
    final M3EThemeData theme = M3ETheme.of(context);
    final int? picked = await M3EBottomSheet.show<int>(
      context,
      theme: theme.bottomSheetTheme,
      builder: (BuildContext sheetContext) {
        // ListTile 需要 Material 祖先；背景由 M3E 底部弹窗提供，此处保持透明。
        return Material(
          type: MaterialType.transparency,
          child: SafeArea(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: totalPages,
              itemBuilder: (BuildContext context, int index) {
                final int pageNumber = index + 1;
                final bool selected = pageNumber == page;
                return ListTile(
                  title: Text('第 $pageNumber 页'),
                  selected: selected,
                  onTap: () => Navigator.of(context).pop(pageNumber),
                );
              },
            ),
          ),
        );
      },
    );
    if (picked != null) {
      onPageChanged(picked);
    }
  }
}
