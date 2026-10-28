import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_reader_chrome_metrics.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

enum Md3eReaderChromeBandEdge { top, bottom }

/// 沉浸顶/底 chrome：全宽不透明 scrim 条（不叠半透明渐变到画布，避免洗白）。
class Md3eReaderChromeBand extends StatelessWidget {
  const Md3eReaderChromeBand({
    super.key,
    required this.edge,
    required this.child,
    this.padding,
  });

  final Md3eReaderChromeBandEdge edge;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  static double contentMaxWidth(BuildContext context) {
    return Md3eReaderChromeMetrics.chromeContentMaxWidth(
      MediaQuery.sizeOf(context).width,
    );
  }

  @override
  Widget build(BuildContext context) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final bool top = edge == Md3eReaderChromeBandEdge.top;

    return ColoredBox(
      color: scheme.scrim,
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: Align(
          alignment: top ? Alignment.topCenter : Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: contentMaxWidth(context),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
