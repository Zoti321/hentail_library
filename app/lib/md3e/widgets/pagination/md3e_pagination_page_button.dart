import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/widgets/pagination/md3e_pagination_metrics.dart';
import 'package:material_3_expressive/foundations/foundations.dart';

/// Single page number control in the standard pagination strip.
class Md3ePaginationPageButton extends StatelessWidget {
  const Md3ePaginationPageButton({
    super.key,
    required this.page,
    required this.selected,
    required this.onPressed,
  });

  final int page;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final TextStyle? labelStyle = textTheme.labelLarge?.copyWith(
      color: selected ? scheme.onPrimaryContainer : scheme.onSurface,
    );

    final Widget face = Container(
      width: Md3ePaginationMetrics.pageButtonVisualSize,
      height: Md3ePaginationMetrics.pageButtonVisualSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? scheme.primaryContainer : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('$page', style: labelStyle),
    );

    return SizedBox(
      width: Md3ePaginationMetrics.pageButtonSlotWidth,
      height: Md3ePaginationMetrics.pageButtonSlotWidth,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Center(child: face),
        ),
      ),
    );
  }
}

/// Ellipsis slot matching [Md3ePaginationPageButton] footprint.
class Md3ePaginationEllipsisSlot extends StatelessWidget {
  const Md3ePaginationEllipsisSlot({super.key, required this.style});

  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: Md3ePaginationMetrics.pageButtonSlotWidth,
      height: Md3ePaginationMetrics.pageButtonSlotWidth,
      child: Center(child: Text('…', style: style)),
    );
  }
}

/// Invisible slot reserved for stable strip width.
class Md3ePaginationEmptySlot extends StatelessWidget {
  const Md3ePaginationEmptySlot({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: Md3ePaginationMetrics.pageButtonSlotWidth,
      height: Md3ePaginationMetrics.pageButtonSlotWidth,
    );
  }
}
