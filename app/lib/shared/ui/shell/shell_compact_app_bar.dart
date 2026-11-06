import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Mobile / tablet shell chrome (&lt; expanded): leading menu only, no search or window controls.
abstract final class ShellCompactAppBarMetrics {
  static const double height = 56;

  static const double leadingPadding = 4;
}

class ShellCompactAppBar extends StatelessWidget {
  const ShellCompactAppBar({super.key, required this.onMenuPressed});

  final VoidCallback onMenuPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: ShellCompactAppBarMetrics.height,
        width: double.infinity,
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(
              start: ShellCompactAppBarMetrics.leadingPadding,
            ),
            child: M3EIconButton(
              icon: const Icon(Icons.menu),
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
              onPressed: onMenuPressed,
              variant: M3EIconButtonVariant.standard,
              size: M3EIconButtonSize.md,
            ),
          ),
        ),
      ),
    );
  }
}
