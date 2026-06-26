import 'package:flutter/material.dart';
import 'package:hentai_library/presentation/theme/theme.dart';

class SeriesDetailCard extends StatelessWidget {
  const SeriesDetailCard({
    super.key,
    required this.maxWidth,
    required this.child,
    this.padding,
  });

  final double maxWidth;
  final Widget child;
  final EdgeInsets? padding;

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
        border: Border.all(color: cs.hentai.borderSubtle),
        borderRadius: radius,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: cs.hentai.cardShadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: radius, child: child),
    );
  }
}
