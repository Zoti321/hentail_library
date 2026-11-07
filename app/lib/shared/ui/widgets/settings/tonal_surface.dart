import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Outer radius for tonal settings cards and split-list groups.
const double kTonalSurfaceRadius = 24;

/// Filled surface block (`surfaceContainerLow`), Kazumi-style tonal card.
class TonalSurface extends StatelessWidget {
  const TonalSurface({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.borderRadius = kTonalSurfaceRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(borderRadius),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    );
  }
}
