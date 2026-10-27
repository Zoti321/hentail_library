import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Outer radius for tonal settings cards and split-list groups.
const double kMd3eTonalSurfaceRadius = 24;

/// Filled surface block (`surfaceContainerLow`), Kazumi-style tonal card.
class Md3eTonalSurface extends StatelessWidget {
  const Md3eTonalSurface({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.borderRadius = kMd3eTonalSurfaceRadius,
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
