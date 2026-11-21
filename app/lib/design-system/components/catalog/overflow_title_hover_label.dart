import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../platform/platform_desktop.dart';

/// Desktop hover delay before showing the full overflow title overlay.
const Duration kOverflowTitleHoverWait = Duration(seconds: 1);

/// Plain white rectangular hover label for truncated catalog titles
/// (browser-title style: square corners, thin border, no shadow).
class OverflowTitleHoverLabel extends StatefulWidget {
  const OverflowTitleHoverLabel({
    super.key,
    required this.text,
    required this.style,
    this.maxLines = 1,
  });

  final String text;
  final TextStyle style;
  final int maxLines;

  @override
  State<OverflowTitleHoverLabel> createState() =>
      _OverflowTitleHoverLabelState();
}

class _OverflowTitleHoverLabelState extends State<OverflowTitleHoverLabel> {
  final LayerLink _link = LayerLink();
  OverlayEntry? _entry;
  Timer? _hoverTimer;
  bool _hovering = false;

  @override
  void dispose() {
    _hoverTimer?.cancel();
    _removeOverlay();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant OverflowTitleHoverLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text || oldWidget.style != widget.style) {
      _removeOverlay();
    }
  }

  void _onEnter(PointerEnterEvent _) {
    if (!isDesktop) {
      return;
    }
    _hovering = true;
    _hoverTimer?.cancel();
    _hoverTimer = Timer(kOverflowTitleHoverWait, _tryShowOverlay);
  }

  void _onExit(PointerExitEvent _) {
    _hovering = false;
    _hoverTimer?.cancel();
    _hoverTimer = null;
    _removeOverlay();
  }

  bool _isOverflowing(BoxConstraints constraints) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      maxLines: widget.maxLines,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: constraints.maxWidth);
    return painter.didExceedMaxLines;
  }

  void _tryShowOverlay() {
    if (!mounted || !_hovering || _entry != null) {
      return;
    }
    final OverlayState? overlay = Overlay.maybeOf(context);
    if (overlay == null) {
      return;
    }
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return;
    }
    final TextPainter painter = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      maxLines: null,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final Size fullSize = painter.size;
    _entry = OverlayEntry(
      builder: (BuildContext context) {
        return IgnorePointer(
          child: CompositedTransformFollower(
            link: _link,
            showWhenUnlinked: false,
            offset: Offset.zero,
            child: Align(
              alignment: AlignmentDirectional.topStart,
              child: Material(
                type: MaterialType.transparency,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFF333333)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: box.size.width,
                        maxWidth: math.max(
                          box.size.width,
                          fullSize.width + 12,
                        ),
                      ),
                      child: Text(
                        widget.text,
                        style: widget.style.copyWith(color: Colors.black),
                        softWrap: false,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(_entry!);
  }

  void _removeOverlay() {
    _entry?.remove();
    _entry = null;
  }

  @override
  Widget build(BuildContext context) {
    final Widget text = Text(
      widget.text,
      maxLines: widget.maxLines,
      overflow: TextOverflow.ellipsis,
      style: widget.style,
    );
    if (!isDesktop) {
      return text;
    }
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool overflowing = _isOverflowing(constraints);
        final Widget child = CompositedTransformTarget(
          link: _link,
          child: text,
        );
        if (!overflowing) {
          return child;
        }
        return MouseRegion(
          onEnter: _onEnter,
          onExit: _onExit,
          child: child,
        );
      },
    );
  }
}
