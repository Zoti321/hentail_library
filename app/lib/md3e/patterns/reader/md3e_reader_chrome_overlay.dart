import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_reader_chrome_metrics.dart';
import 'package:hentai_library/md3e/motion/md3e_motion.dart';
import 'package:hentai_library/md3e/patterns/reader/md3e_reader_chrome_scope.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:motor/motor.dart';

/// 顶/底 chrome 显隐：motor 弹簧驱动（M3E expressive spatial，同工具栏显隐手感）。
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
  /// 无界控制器：弹簧允许轻微过冲（M3E 手感），透明度在 build 内 clamp。
  late final SingleMotionController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SingleMotionController(
      motion: Md3eMotion.readerChromeReveal,
      vsync: this,
      initialValue: widget.visible ? 1 : 0,
    );
  }

  @override
  void didUpdateWidget(Md3eReaderChromeReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible == widget.visible) {
      return;
    }
    final double target = widget.visible ? 1 : 0;
    if (Md3eMotion.reduceMotionOf(context)) {
      _controller.value = target;
    } else {
      _controller.animateTo(target);
    }
  }

  @override
  void dispose() {
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
          child: Opacity(opacity: widget.visible ? 1 : 0, child: widget.child),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double raw = _controller.value;
        final double opacity = raw.clamp(0.0, 1.0);
        final double slide = (1 - raw) * Md3eReaderChromeMetrics.hideSlidePx;
        final double dy = widget.top ? -slide : slide;
        return IgnorePointer(
          ignoring: opacity <= 0.01,
          child: ExcludeSemantics(
            excluding: opacity <= 0.01,
            child: Transform.translate(
              offset: Offset(0, dy),
              child: Opacity(opacity: opacity, child: child),
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
