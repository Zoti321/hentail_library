import 'package:flutter/material.dart';
import 'package:hentai_library/theme/theme.dart';

class ComicDetailCard extends StatelessWidget {
  const ComicDetailCard({
    super.key,
    required this.maxWidth,
    this.padding,
    required this.child,
  });
  final double maxWidth;
  final EdgeInsets? padding;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final BorderRadius radius = BorderRadius.circular(tokens.radius.lg);
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: padding,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: radius,
        border: Border.all(color: cs.borderSubtle),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: cs.cardShadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: radius, child: child),
    );
  }
}
