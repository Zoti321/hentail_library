import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/widgets/pagination/pagination_metrics.dart';

/// Ellipsis slot matching [PaginationPageButton] footprint.
class PaginationEllipsisSlot extends StatelessWidget {
  const PaginationEllipsisSlot({super.key, required this.style});

  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: PaginationMetrics.pageButtonSlotWidth,
      height: PaginationMetrics.pageButtonSlotWidth,
      child: Center(child: Text('…', style: style)),
    );
  }
}
