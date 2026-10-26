import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/widgets/md3e_pagination_compact.dart';
import 'package:hentai_library/md3e/widgets/md3e_pagination_metrics.dart';
import 'package:hentai_library/md3e/widgets/md3e_pagination_standard.dart';
import 'package:material_3_expressive/foundations/foundations.dart';

/// Responsive MD3E pagination (Lab only; production uses [LibraryPaginationBar]).
class Md3ePagination extends StatelessWidget {
  const Md3ePagination({
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

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final Md3eWindowSizeClass sizeClass =
            Md3eWindowSizeClass.fromWidth(width);

        final bool useCompact = sizeClass.isCompact ||
            width < Md3ePaginationMetrics.standardBarMinWidth(sizeClass);

        if (useCompact) {
          return Md3ePaginationCompact(
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

        return Md3ePaginationStandard(
          page: clampedPage,
          totalPages: totalPages,
          enabled: enabled,
          sizeClass: sizeClass,
          onPageChanged: onPageChanged,
        );
      },
    );
  }

  static Future<void> _showCompactPagePicker({
    required BuildContext context,
    required int page,
    required int totalPages,
    required ValueChanged<int> onPageChanged,
  }) async {
    final M3EThemeData theme = M3ETheme.of(context);
    final int? picked = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return M3ETheme(
          data: theme,
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
