import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';

class PopupMenuPanelShell extends StatelessWidget {
  const PopupMenuPanelShell({
    required this.width,
    required this.blurRadius,
    required this.shadowOffset,
    required this.child,
    this.borderRadius,
    super.key,
  });

  final double width;
  final double blurRadius;
  final Offset shadowOffset;
  final Widget child;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final double resolvedBorderRadius = borderRadius ?? tokens.radius.lg;
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(resolvedBorderRadius),
        border: Border.all(color: colorScheme.hentai.borderSubtle),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colorScheme.hentai.cardShadowHover,
            blurRadius: blurRadius,
            offset: shadowOffset,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(resolvedBorderRadius),
        child: child,
      ),
    );
  }
}
