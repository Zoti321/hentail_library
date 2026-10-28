import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_reader_chrome_metrics.dart';
import 'package:hentai_library/md3e/motion/md3e_motion.dart';
import 'package:hentai_library/md3e/patterns/reader/md3e_reader_chrome_scope.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 顶/底 chrome 显隐：单控制器 + M3E 强调曲线（250ms，对齐 app bar travel）。
class Md3eReaderChromeReveal extends StatefulWidget {
  const Md3eReaderChromeReveal({
    super.key,
    required this.visible,
    required this.top,
    required this.child,
  });

  final bool visible;
  final bool top;
  final Widget child;

  @override
  State<Md3eReaderChromeReveal> createState() => _Md3eReaderChromeRevealState();
}

class _Md3eReaderChromeRevealState extends State<Md3eReaderChromeReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  CurvedAnimation? _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Md3eMotion.readerChromeTravel,
      value: widget.visible ? 1 : 0,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animation?.dispose();
    final bool reduceMotion = Md3eMotion.reduceMotionOf(context);
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Md3eMotion.readerChromeCurveForReveal(reduceMotion: reduceMotion),
      reverseCurve:
          Md3eMotion.readerChromeCurveForDismiss(reduceMotion: reduceMotion),
    );
    if (widget.visible) {
      _controller.value = 1;
    } else {
      _controller.value = 0;
    }
  }

  @override
  void didUpdateWidget(Md3eReaderChromeReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible == widget.visible) {
      return;
    }
    if (widget.visible) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _animation?.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Md3eMotion.reduceMotionOf(context)) {
      return IgnorePointer(
        ignoring: !widget.visible,
        child: ExcludeSemantics(
          excluding: !widget.visible,
          child: Opacity(
            opacity: widget.visible ? 1 : 0,
            child: widget.child,
          ),
        ),
      );
    }

    final Animation<double> animation = _animation!;

    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        final double t = animation.value;
        final double slide = (1 - t) * Md3eReaderChromeMetrics.hideSlidePx;
        final double dy = widget.top ? -slide : slide;
        return IgnorePointer(
          ignoring: t <= 0.01,
          child: ExcludeSemantics(
            excluding: t <= 0.01,
            child: Transform.translate(
              offset: Offset(0, dy),
              child: Opacity(opacity: t, child: child),
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}

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
            child: Md3eReaderChromeReveal(
              visible: visible,
              top: true,
              child: topBar,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Md3eReaderChromeReveal(
              visible: visible,
              top: false,
              child: bottomBar,
            ),
          ),
        ],
      ),
    );
  }
}
