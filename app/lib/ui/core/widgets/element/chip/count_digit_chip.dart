import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';

/// Compact count badge: digits only, full meaning via [semanticLabel].
class CountDigitChip extends StatelessWidget {
  const CountDigitChip({
    super.key,
    required this.count,
    required this.semanticLabel,
  });

  final int count;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Semantics(
      label: semanticLabel,
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.hentai.borderSubtle),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.hentai.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
