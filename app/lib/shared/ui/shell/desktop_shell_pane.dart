import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/shell/desktop_shell_metrics.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Main pane surface (role from [DesktopShellSurfaceRoles], r=20).
class DesktopShellPane extends StatelessWidget {
  const DesktopShellPane({
    super.key,
    this.backgroundColor,
    this.borderRadius,
    this.showDecoration = true,
    this.child,
  });

  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final bool showDecoration;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final Widget content = child ?? const SizedBox.expand();
    if (!showDecoration) {
      return content;
    }

    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final Color fill = backgroundColor ?? scheme.surfaceContainerLowest;
    final BorderRadius radius =
        borderRadius ??
        const BorderRadius.all(
          Radius.circular(DesktopShellMetrics.paneCornerRadius),
        );

    return DecoratedBox(
      decoration: BoxDecoration(color: fill, borderRadius: radius),
      child: content,
    );
  }
}
