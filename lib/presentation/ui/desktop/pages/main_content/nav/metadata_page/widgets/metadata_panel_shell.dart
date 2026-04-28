import 'package:flutter/material.dart';
import 'package:hentai_library/presentation/theme/theme.dart';

class MetadataPanelListCard extends StatelessWidget {
  const MetadataPanelListCard({
    required this.radius,
    required this.child,
    super.key,
  });

  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: colorScheme.borderSubtle),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: child,
      ),
    );
  }
}

class MetadataPanelRowInteractionShell extends StatelessWidget {
  const MetadataPanelRowInteractionShell({
    required this.hoverColor,
    required this.materialColor,
    required this.child,
    super.key,
  });

  final Color hoverColor;
  final Color materialColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: hoverColor,
      ),
      child: Material(color: materialColor, child: child),
    );
  }
}
