import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/widgets/pagination/pagination_metrics.dart';

/// Invisible slot reserved for stable strip width.
class PaginationEmptySlot extends StatelessWidget {
  const PaginationEmptySlot({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: PaginationMetrics.pageButtonSlotWidth,
      height: PaginationMetrics.pageButtonSlotWidth,
    );
  }
}
