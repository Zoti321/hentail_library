import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/widgets/pagination/md3e_pagination_metrics.dart';
import 'package:hentai_library/md3e/motion/md3e_spring_positioned.dart';
import 'package:hentai_library/md3e/widgets/pagination/md3e_pagination_page_button.dart';
import 'package:hentai_library/md3e/widgets/pagination/md3e_pagination_page_window.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Page-number strip with a single animated selection block (no strip-wide switch).
class Md3ePaginationStandardPageStrip extends StatelessWidget {
  const Md3ePaginationStandardPageStrip({
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
  final Md3eWindowSizeClass sizeClass;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: Md3ePaginationMetrics.pageNumberStripWidth(sizeClass),
      child: _Md3ePaginationSelectionStrip(
        page: page,
        totalPages: totalPages,
        enabled: enabled,
        sizeClass: sizeClass,
        onPageChanged: onPageChanged,
      ),
    );
  }
}

class _Md3ePaginationSelectionStrip extends StatefulWidget {
  const _Md3ePaginationSelectionStrip({
    required this.page,
    required this.totalPages,
    required this.enabled,
    required this.sizeClass,
    required this.onPageChanged,
  });

  final int page;
  final int totalPages;
  final bool enabled;
  final Md3eWindowSizeClass sizeClass;
  final ValueChanged<int> onPageChanged;

  @override
  State<_Md3ePaginationSelectionStrip> createState() =>
      _Md3ePaginationSelectionStripState();
}

class _Md3ePaginationSelectionStripState
    extends State<_Md3ePaginationSelectionStrip> {
  List<Md3ePaginationWindowItem> _windowItems() {
    final Md3ePaginationSiblingConfig config =
        Md3ePaginationMetrics.siblingConfigFor(widget.sizeClass);
    final int slotCount = Md3ePaginationMetrics.fixedPageSlotCount(
      widget.sizeClass,
    );
    return md3ePadPaginationPageWindow(
      md3eBuildPaginationPageWindow(
        currentPage: widget.page,
        totalPages: widget.totalPages,
        config: config,
      ),
      slotCount: slotCount,
    );
  }

  int? _selectedSlotIndex(List<Md3ePaginationWindowItem> window) {
    for (int i = 0; i < window.length; i++) {
      final Md3ePaginationWindowItem item = window[i];
      if (item is Md3ePaginationWindowPage && item.page == widget.page) {
        return i;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bool interactive = widget.enabled;
    final List<Md3ePaginationWindowItem> window = _windowItems();
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final TextStyle? ellipsisStyle = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: scheme.onSurfaceVariant);
    final int? selectedIndex = _selectedSlotIndex(window);
    final double slot = Md3ePaginationMetrics.pageButtonSlotWidth;
    final double visual = Md3ePaginationMetrics.pageButtonVisualSize;
    final double inset = (slot - visual) / 2;

    return SizedBox(
      height: Md3ePaginationMetrics.pageButtonSlotWidth,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.centerLeft,
        children: <Widget>[
          if (selectedIndex != null)
            Md3eSpringPositioned(
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
              for (final Md3ePaginationWindowItem item in window)
                switch (item) {
                  Md3ePaginationWindowPage(:final int page) =>
                    Md3ePaginationPageButton(
                      key: ValueKey<int>(page),
                      page: page,
                      selected: page == widget.page,
                      showSelectionFill: false,
                      onPressed: interactive && page != widget.page
                          ? () => widget.onPageChanged(page)
                          : null,
                    ),
                  Md3ePaginationWindowEllipsis() =>
                    Md3ePaginationEllipsisSlot(style: ellipsisStyle),
                  Md3ePaginationWindowEmpty() =>
                    const Md3ePaginationEmptySlot(),
                },
            ],
          ),
        ],
      ),
    );
  }
}
