import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/interaction/md3e_pointer_target.dart';
import 'package:hentai_library/md3e/widgets/pagination/md3e_pagination_metrics.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Compact (&lt; 600dp) pagination: large icon prev/next and tappable page summary.
class Md3ePaginationCompact extends StatelessWidget {
  const Md3ePaginationCompact({
    super.key,
    required this.page,
    required this.totalPages,
    required this.onPageChanged,
    required this.enabled,
    this.onOpenPagePicker,
  });

  final int page;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final bool enabled;
  final VoidCallback? onOpenPagePicker;

  @override
  Widget build(BuildContext context) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final TextStyle? summaryStyle = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: scheme.onSurfaceVariant);
    final bool canGoPrevious = enabled && page > 1;
    final bool canGoNext = enabled && page < totalPages;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Md3ePaginationMetrics.horizontalPaddingCompact,
        vertical: 8,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: _CompactNavIcon(
                icon: Icons.chevron_left,
                tooltip: '上一页',
                onPressed:
                    canGoPrevious ? () => onPageChanged(page - 1) : null,
              ),
            ),
          ),
          Md3ePointerTarget(
            onTap: enabled ? onOpenPagePicker : null,
            child: SizedBox(
              width: Md3ePaginationMetrics.compactPageSummaryMinWidth,
              child: Text(
                '$page / $totalPages',
                style: summaryStyle,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: _CompactNavIcon(
                icon: Icons.chevron_right,
                tooltip: '下一页',
                onPressed: canGoNext ? () => onPageChanged(page + 1) : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactNavIcon extends StatelessWidget {
  const _CompactNavIcon({
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
      width: Md3ePaginationMetrics.compactNavIconSlot,
      height: Md3ePaginationMetrics.compactNavIconSlot,
      child: Center(
        child: M3EIconButton(
          icon: Icon(
            icon,
            size: Md3ePaginationMetrics.compactNavIconSize,
          ),
          variant: M3EIconButtonVariant.standard,
          size: M3EIconButtonSize.md,
          tooltip: tooltip,
          onPressed: onPressed,
        ),
      ),
    );
  }
}
