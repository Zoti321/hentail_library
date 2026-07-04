import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';

/// 仅用于 R18 年龄限制的红色胶囊 chip。
class R18RatingChip extends StatelessWidget {
  const R18RatingChip({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cs.error,
        borderRadius: BorderRadius.circular(tokens.radius.pill),
      ),
      child: Text(
        'R18',
        style: TextStyle(
          fontSize: tokens.text.labelXs,
          fontWeight: FontWeight.w600,
          color: cs.onError,
          height: 1.1,
        ),
      ),
    );
  }
}
