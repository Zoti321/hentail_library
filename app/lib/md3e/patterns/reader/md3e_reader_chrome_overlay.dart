import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_reader_chrome_metrics.dart';
import 'package:hentai_library/md3e/motion/md3e_motion.dart';
import 'package:hentai_library/md3e/patterns/reader/md3e_reader_chrome_scope.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 顶/底 chrome 的显隐与 safe-area 定位（全宽 scrim，非浮岛）。
class Md3eReaderChromeOverlay extends StatelessWidget {
  const Md3eReaderChromeOverlay({
    super.key,
    required this.visible,
    required this.topBar,
    required this.bottomBar,
  });

  final bool visible;
  final Widget topBar;
  final Widget bottomBar;

  @override
  Widget build(BuildContext context) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final bool reduceMotion = Md3eMotion.reduceMotionOf(context);
    final Duration duration = Md3eMotion.motionDurationOf(
      context,
      Md3eMotion.durationShort,
    );
    final Curve curve = visible
        ? Md3eMotion.curveForStateEnter(reduceMotion: reduceMotion)
        : Md3eMotion.curveForStateExit(reduceMotion: reduceMotion);
    final double slide = Md3eReaderChromeMetrics.hideSlideFraction;

    Widget wrapVertical({
      required bool top,
      required Widget child,
    }) {
      return IgnorePointer(
        ignoring: !visible,
        child: ExcludeSemantics(
          excluding: !visible,
          child: AnimatedSlide(
            duration: duration,
            curve: curve,
            offset: visible
                ? Offset.zero
                : Offset(0, top ? -slide : slide),
            child: AnimatedOpacity(
              duration: duration,
              curve: curve,
              opacity: visible ? 1 : 0,
              child: child,
            ),
          ),
        ),
      );
    }

    return Md3eReaderChromeScope(
      onChrome: Md3eReaderImmersiveColors.onChrome(scheme),
      onChromeVariant: Md3eReaderImmersiveColors.onChromeVariant(scheme),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: wrapVertical(
              top: true,
              child: topBar,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: wrapVertical(
              top: false,
              child: bottomBar,
            ),
          ),
        ],
      ),
    );
  }
}
