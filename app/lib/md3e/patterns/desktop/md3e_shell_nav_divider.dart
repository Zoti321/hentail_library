import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Vertical rule between rail and library secondary pane (M3 nav chrome).
class Md3eShellNavVerticalDivider extends StatelessWidget {
  const Md3eShellNavVerticalDivider({
    super.key,
    this.color,
    this.height,
  });

  final Color? color;
  final double? height;

  static const double thickness = 1;

  @override
  Widget build(BuildContext context) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final Color line = color ?? scheme.outlineVariant;

    return SizedBox(
      width: thickness,
      height: height ?? double.infinity,
      child: ColoredBox(color: line),
    );
  }
}
