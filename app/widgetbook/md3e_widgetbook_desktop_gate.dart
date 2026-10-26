import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Shows [child] only when Widgetbook [ViewportAddon] width is expanded (≥840dp).
///
/// Widgetbook has no per-use-case viewport lock; pick **Expanded** or wider in the
/// toolbar, or read the fallback message below.
class Md3eWidgetbookDesktopExpandedGate extends StatelessWidget {
  const Md3eWidgetbookDesktopExpandedGate({
    super.key,
    required this.child,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    if (width < Md3eBreakpoints.expanded) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '此用例仅适用于桌面壳（窗口宽 ≥ ${Md3eBreakpoints.expanded.toInt()}dp）。'
            '请在 Widgetbook 左侧 Viewport 中选择「Expanded (840–1199dp)」或更宽档位。',
            textAlign: TextAlign.center,
            style: M3ETheme.of(context).typeScale.bodyLarge.copyWith(
              color: M3ETheme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Align(alignment: alignment, child: child);
  }
}
