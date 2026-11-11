import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/shared/ui/widgets/pagination/pagination_metrics.dart';
import 'package:hentai_library/shared/ui/widgets/pagination/pagination_page_button.dart';
import 'package:hentai_library/shared/ui/widgets/pagination/pagination_page_window.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Page-number strip with a single animated selection block (no strip-wide switch).
class PaginationStandardPageStrip extends StatelessWidget {
  const PaginationStandardPageStrip({
    super.key,
    required this.page,
    required this.totalPages,
    required this.enabled,
    required this.sizeClass,
    required this.onPageChanged,
  });

  final int page;
  final int totalPages;
  final bool enabled;
  final WindowSizeClass sizeClass;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: PaginationMetrics.pageNumberStripWidth(sizeClass),
      child: _PaginationSelectionStrip(
        page: page,
        totalPages: totalPages,
        enabled: enabled,
        sizeClass: sizeClass,
        onPageChanged: onPageChanged,
      ),
    );
  }
}

class _PaginationSelectionStrip extends StatefulWidget {
  const _PaginationSelectionStrip({
    required this.page,
    required this.totalPages,
    required this.enabled,
    required this.sizeClass,
    required this.onPageChanged,
  });

  final int page;
  final int totalPages;
  final bool enabled;
  final WindowSizeClass sizeClass;
  final ValueChanged<int> onPageChanged;

  @override
  State<_PaginationSelectionStrip> createState() =>
      _PaginationSelectionStripState();
}

class _PaginationSelectionStripState extends State<_PaginationSelectionStrip> {
  List<PaginationWindowItem> _windowItems() {
    final PaginationSiblingConfig config = PaginationMetrics.siblingConfigFor(
      widget.sizeClass,
    );
    final int slotCount = PaginationMetrics.fixedPageSlotCount(
      widget.sizeClass,
    );
    return padPaginationPageWindow(
      buildPaginationPageWindow(
        currentPage: widget.page,
        totalPages: widget.totalPages,
        config: config,
      ),
      slotCount: slotCount,
    );
  }

  int? _selectedSlotIndex(List<PaginationWindowItem> window) {
    for (int i = 0; i < window.length; i++) {
      final PaginationWindowItem item = window[i];
      if (item is PaginationWindowPage && item.page == widget.page) {
        return i;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bool interactive = widget.enabled;
    final List<PaginationWindowItem> window = _windowItems();
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final TextStyle? ellipsisStyle = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: scheme.onSurfaceVariant);
    final int? selectedIndex = _selectedSlotIndex(window);
    final double slot = PaginationMetrics.pageButtonSlotWidth;
    final double visual = PaginationMetrics.pageButtonVisualSize;
    final double inset = (slot - visual) / 2;

    return SizedBox(
      height: PaginationMetrics.pageButtonSlotWidth,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.centerLeft,
        children: <Widget>[
          if (selectedIndex != null)
            SpringPositioned(
              rect: Rect.fromLTWH(
                selectedIndex * slot + inset,
                inset,
                visual,
                visual,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              for (final PaginationWindowItem item in window)
                switch (item) {
                  PaginationWindowPage(:final int page) => PaginationPageButton(
                    key: ValueKey<int>(page),
                    page: page,
                    selected: page == widget.page,
                    showSelectionFill: false,
                    onPressed: interactive && page != widget.page
                        ? () => widget.onPageChanged(page)
                        : null,
                  ),
                  PaginationWindowEllipsis() => PaginationEllipsisSlot(
                    style: ellipsisStyle,
                  ),
                  PaginationWindowEmpty() => const PaginationEmptySlot(),
                },
            ],
          ),
        ],
      ),
    );
  }
}
