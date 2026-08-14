import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';

class PopupMenuPanelShell extends StatelessWidget {
  const PopupMenuPanelShell({
    this.width,
    this.maxWidth,
    required this.blurRadius,
    required this.shadowOffset,
    required this.child,
    this.borderRadius,
    super.key,
  }) : assert(
         width != null || maxWidth != null,
         'PopupMenuPanelShell requires width and/or maxWidth',
       );

  /// Fixed panel width. When null, width hugs content up to [maxWidth].
  final double? width;

  /// Caps intrinsic width when [width] is null; ignored when [width] is set.
  final double? maxWidth;
  final double blurRadius;
  final Offset shadowOffset;
  final Widget child;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final double resolvedBorderRadius = borderRadius ?? tokens.radius.lg;
    final Widget panel = Container(
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
    if (width != null) {
      return panel;
    }
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth!),
      child: IntrinsicWidth(child: panel),
    );
  }
}
