import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/widgets/md3e_pagination_metrics.dart';
import 'package:hentai_library/md3e/widgets/md3e_pagination_page_button.dart';
import 'package:hentai_library/md3e/widgets/md3e_pagination_page_window.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Standard (≥ 600dp) pagination: MUI-like page window + first/prev/next/last.
class Md3ePaginationStandard extends StatelessWidget {
  const Md3ePaginationStandard({
    super.key,
    required this.page,
    required this.totalPages,
    required this.onPageChanged,
    required this.enabled,
    required this.sizeClass,
  });

  final int page;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final bool enabled;
  final Md3eWindowSizeClass sizeClass;

  @override
  Widget build(BuildContext context) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final TextStyle? summaryStyle = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: scheme.onSurfaceVariant);
    final bool interactive = enabled;
    final bool canGoPrevious = interactive && page > 1;
    final bool canGoNext = interactive && page < totalPages;

    final Md3ePaginationSiblingConfig config =
        Md3ePaginationMetrics.siblingConfigFor(sizeClass);
    final int slotCount = Md3ePaginationMetrics.fixedPageSlotCount(sizeClass);
    final List<Md3ePaginationWindowItem> window = md3ePadPaginationPageWindow(
      md3eBuildPaginationPageWindow(
        currentPage: page,
        totalPages: totalPages,
        config: config,
      ),
      slotCount: slotCount,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Md3ePaginationMetrics.horizontalPaddingStandard,
        vertical: 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          _NavIcon(
            icon: Icons.first_page,
            tooltip: '首页',
            onPressed: canGoPrevious ? () => onPageChanged(1) : null,
          ),
          _NavIcon(
            icon: Icons.chevron_left,
            tooltip: '上一页',
            onPressed: canGoPrevious ? () => onPageChanged(page - 1) : null,
          ),
          SizedBox(
            width: Md3ePaginationMetrics.pageNumberStripWidth(sizeClass),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                for (final Md3ePaginationWindowItem item in window)
                  switch (item) {
                    Md3ePaginationWindowPage(:final int page) =>
                      Md3ePaginationPageButton(
                        key: ValueKey<int>(page),
                        page: page,
                        selected: page == this.page,
                        onPressed: interactive && page != this.page
                            ? () => onPageChanged(page)
                            : null,
                      ),
                    Md3ePaginationWindowEllipsis() =>
                      Md3ePaginationEllipsisSlot(style: summaryStyle),
                    Md3ePaginationWindowEmpty() =>
                      const Md3ePaginationEmptySlot(),
                  },
              ],
            ),
          ),
          _NavIcon(
            icon: Icons.chevron_right,
            tooltip: '下一页',
            onPressed: canGoNext ? () => onPageChanged(page + 1) : null,
          ),
          _NavIcon(
            icon: Icons.last_page,
            tooltip: '末页',
            onPressed: canGoNext ? () => onPageChanged(totalPages) : null,
          ),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: Md3ePaginationMetrics.standardNavIconSlot,
      height: Md3ePaginationMetrics.standardNavIconSlot,
      child: Center(
        child: M3EIconButton(
          icon: Icon(icon, size: Md3ePaginationMetrics.iconSize),
          variant: M3EIconButtonVariant.standard,
          size: M3EIconButtonSize.sm,
          tooltip: tooltip,
          onPressed: onPressed,
        ),
      ),
    );
  }
}
