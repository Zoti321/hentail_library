import 'package:flutter/material.dart';
import 'package:hentai_library/config/theme.dart';

class PopupMenuPanelShell extends StatelessWidget {
  const PopupMenuPanelShell({
    required this.width,
    required this.blurRadius,
    required this.shadowOffset,
    required this.child,
    super.key,
  });

  final double width;
  final double blurRadius;
  final Offset shadowOffset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(tokens.radius.lg),
        border: Border.all(color: colorScheme.borderSubtle),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colorScheme.cardShadowHover,
            blurRadius: blurRadius,
            offset: shadowOffset,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(tokens.radius.lg),
        child: child,
      ),
    );
  }
}
