import 'package:flutter/material.dart';

/// "current / total" label for [Md3ePaginationCompact] (no strip animation).
class Md3ePaginationCompactSummary extends StatelessWidget {
  const Md3ePaginationCompactSummary({
    super.key,
    required this.page,
    required this.totalPages,
    required this.style,
  });

  final int page;
  final int totalPages;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text(
      key: ValueKey<int>(page),
      '$page / $totalPages',
      style: style,
      textAlign: TextAlign.center,
    );
  }
}
