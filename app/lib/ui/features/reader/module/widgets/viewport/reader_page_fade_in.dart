import 'package:flutter/material.dart';
import 'package:hentai_library/ui/features/reader/module/widgets/viewport/reader_viewport_constants.dart';

class ReaderPageFadeIn extends StatefulWidget {
  const ReaderPageFadeIn({
    super.key,
    required this.enabled,
    required this.child,
  });

  final bool enabled;
  final Widget child;

  @override
  State<ReaderPageFadeIn> createState() => _ReaderPageFadeInState();
}

class _ReaderPageFadeInState extends State<ReaderPageFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: kReaderPageCrossfadeDuration,
  );
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant ReaderPageFadeIn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.enabled && widget.enabled) {
      _controller.forward(from: 0);
    } else if (!widget.enabled) {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}
