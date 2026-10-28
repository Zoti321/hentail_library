import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_reader_chrome_metrics.dart';
import 'package:hentai_library/md3e/patterns/reader/md3e_reader_page_copy.dart';
import 'package:hentai_library/md3e/patterns/reader/md3e_reader_chrome_scope.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Lab 阅读画布占位：竖向贴边、左右 letterbox（非 FRB 图像）。
class Md3eReaderViewportPlaceholder extends StatelessWidget {
  const Md3eReaderViewportPlaceholder({
    super.key,
    required this.page,
    this.showEdgeHints = false,
  });

  final int page;
  final bool showEdgeHints;

  @override
  Widget build(BuildContext context) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final M3ETypeScale type = M3ETheme.of(context).typeScale;
    final double horizontalInset = Md3eReaderChromeMetrics.viewportHorizontalInset(
      MediaQuery.sizeOf(context).width,
    );
    final Color hintColor =
        Md3eReaderChromeScope.maybeOf(context)?.onChromeVariant ??
        scheme.onSurfaceVariant;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalInset),
      child: ColoredBox(
        color: scheme.surfaceBright,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Center(
              child: Text(
                Md3eReaderPageCopy.viewportPlaceholder(page),
                style: type.bodyLarge.copyWith(
                  color: scheme.scrim.withValues(alpha: 0.35),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (showEdgeHints) ...<Widget>[
              _EdgeHint(
                alignment: Alignment.centerLeft,
                icon: Symbols.chevron_left,
                color: hintColor,
              ),
              _EdgeHint(
                alignment: Alignment.centerRight,
                icon: Symbols.chevron_right,
                color: hintColor,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EdgeHint extends StatelessWidget {
  const _EdgeHint({
    required this.alignment,
    required this.icon,
    required this.color,
  });

  final Alignment alignment;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Icon(
          icon,
          size: 36,
          color: color.withValues(alpha: 0.28),
        ),
      ),
    );
  }
}
