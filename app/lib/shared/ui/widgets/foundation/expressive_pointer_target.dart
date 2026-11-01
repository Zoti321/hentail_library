import 'package:flutter/material.dart';

/// Material minimum interactive target (48dp) for MD3E controls.
const double kMd3eMinInteractiveSize = 48;

/// Expands hit area to at least [minSize] without changing child layout intent.
class Md3ePointerTarget extends StatelessWidget {
  const Md3ePointerTarget({
    super.key,
    required this.child,
    this.onTap,
    this.minSize = kMd3eMinInteractiveSize,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double minSize;

  @override
  Widget build(BuildContext context) {
    final Widget aligned = Align(
      widthFactor: 1,
      heightFactor: 1,
      child: child,
    );
    final Widget sized = ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minSize,
        minHeight: minSize,
      ),
      child: aligned,
    );
    if (onTap == null) {
      return sized;
    }
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: sized,
      ),
    );
  }
}
