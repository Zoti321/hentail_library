import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../platform/platform_desktop.dart';

/// Desktop hover delay before showing the full overflow title overlay.
const Duration kOverflowTitleHoverWait = Duration(seconds: 1);

/// Offset from the pointer tip to the label's top-left (tight to the cursor).
const Offset kOverflowTitleHoverCursorOffset = Offset(4, 8);

/// Max label width before soft-wrapping (Windows tooltip content width ~320).
const double kOverflowTitleHoverMaxWidth = 320;

/// Inset from the root overlay edges when fitting the label.
const double kOverflowTitleHoverEdgeMargin = 4;

/// Caption-scale label style: smaller and lighter than catalog titles so the
/// overlay reads as a crisp desktop hover tip rather than a bold title clone.
const TextStyle kOverflowTitleHoverLabelStyle = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w400,
  height: 1.25,
  letterSpacing: 0,
  color: Color(0xFF1A1A1A),
);

/// Plain rectangular hover label for truncated catalog titles.
///
/// Placement matches other design-system overlays (see `anchored_menu.dart`):
/// insert into the **root** [Overlay], convert [PointerEvent.position] via
/// [RenderBox.globalToLocal], then fit inside the overlay bounds.
class OverflowTitleHoverLabel extends StatefulWidget {
  const OverflowTitleHoverLabel({
    super.key,
    required this.text,
    required this.style,
    this.maxLines = 1,
  });

  final String text;

  /// Style of the truncated in-place title (used only for overflow measure).
  final TextStyle style;
  final int maxLines;

  @override
  State<OverflowTitleHoverLabel> createState() =>
      _OverflowTitleHoverLabelState();
}

class _OverflowTitleHoverLabelState extends State<OverflowTitleHoverLabel> {
  OverlayEntry? _entry;
  Timer? _hoverTimer;
  bool _hovering = false;

  /// Pointer position in the **global** coordinate space ([PointerEvent.position]).
  Offset? _pointerGlobal;

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

  void _onEnter(PointerEnterEvent event) {
    if (!isDesktop) {
      return;
    }
    _hovering = true;
    _pointerGlobal = event.position;
    _hoverTimer?.cancel();
    _hoverTimer = Timer(kOverflowTitleHoverWait, _tryShowOverlay);
  }

  void _onHover(PointerHoverEvent event) {
    _pointerGlobal = event.position;
    if (_entry != null) {
      _entry!.markNeedsBuild();
    }
  }

  void _onExit(PointerExitEvent _) {
    _hovering = false;
    _pointerGlobal = null;
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
    if (!mounted || !_hovering || _entry != null || _pointerGlobal == null) {
      return;
    }
    // Same root overlay as context menus — nested overlays (shell / routes)
    // have a different origin; using them with global coords misplaces the tip.
    final OverlayState overlay = Overlay.of(context, rootOverlay: true);
    _entry = OverlayEntry(builder: _buildOverlay);
    overlay.insert(_entry!);
  }

  /// Prefer pointer bottom-right; if that overflows, flip above and/or shift
  /// left so the full label stays inside the root overlay.
  static Offset _fitToOverlay({
    required Offset preferredTopLeft,
    required Offset pointerLocal,
    required Size labelSize,
    required Size overlaySize,
  }) {
    const double margin = kOverflowTitleHoverEdgeMargin;
    final double maxLeft = math.max(
      margin,
      overlaySize.width - margin - labelSize.width,
    );
    final double maxTop = math.max(
      margin,
      overlaySize.height - margin - labelSize.height,
    );

    double left = preferredTopLeft.dx;
    double top = preferredTopLeft.dy;

    // Horizontal: keep fully visible; if preferred overflows right, try the
    // left side of the cursor, then clamp into the overlay.
    if (left + labelSize.width > overlaySize.width - margin) {
      left = pointerLocal.dx - kOverflowTitleHoverCursorOffset.dx - labelSize.width;
    }
    left = left.clamp(margin, maxLeft);

    // Vertical: prefer below cursor; flip above when needed, then clamp.
    if (top + labelSize.height > overlaySize.height - margin) {
      top = pointerLocal.dy - kOverflowTitleHoverCursorOffset.dy - labelSize.height;
    }
    top = top.clamp(margin, maxTop);

    return Offset(left, top);
  }

  Widget _buildOverlay(BuildContext overlayContext) {
    final Offset? pointerGlobal = _pointerGlobal;
    if (pointerGlobal == null || !mounted) {
      return const SizedBox.shrink();
    }

    // Convert global → root-overlay local (same as menuGlobalToRootOverlayLocal).
    final OverlayState overlay = Overlay.of(context, rootOverlay: true);
    final RenderBox? overlayBox =
        overlay.context.findRenderObject() as RenderBox?;
    if (overlayBox == null || !overlayBox.hasSize || !overlayBox.attached) {
      return const SizedBox.shrink();
    }
    final Offset pointerLocal = overlayBox.globalToLocal(pointerGlobal);
    final Size overlaySize = overlayBox.size;

    final MediaQueryData media = MediaQuery.of(context);
    const TextStyle labelStyle = kOverflowTitleHoverLabelStyle;
    final double borderWidth = math.max(1 / media.devicePixelRatio, 0.5);
    const EdgeInsets labelPadding = EdgeInsets.symmetric(
      horizontal: 6,
      vertical: 3,
    );

    final double maxContentWidth = math.max(
      40,
      math.min(
        kOverflowTitleHoverMaxWidth,
        overlaySize.width -
            kOverflowTitleHoverEdgeMargin * 2 -
            labelPadding.horizontal -
            borderWidth * 2,
      ),
    );

    final TextPainter measure = TextPainter(
      text: TextSpan(text: widget.text, style: labelStyle),
      textDirection: Directionality.of(context),
      textScaler: media.textScaler,
    )..layout(maxWidth: maxContentWidth);

    final Size labelSize = Size(
      measure.width + labelPadding.horizontal + borderWidth * 2,
      measure.height + labelPadding.vertical + borderWidth * 2,
    );

    final Offset preferred = pointerLocal + kOverflowTitleHoverCursorOffset;
    final Offset fitted = _fitToOverlay(
      preferredTopLeft: preferred,
      pointerLocal: pointerLocal,
      labelSize: labelSize,
      overlaySize: overlaySize,
    );

    return IgnorePointer(
      child: Stack(
        children: <Widget>[
          Positioned(
            left: fitted.dx,
            top: fitted.dy,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: const Color(0xFF767676),
                  width: borderWidth,
                ),
              ),
              child: Padding(
                padding: labelPadding,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxContentWidth),
                  child: Text(
                    widget.text,
                    style: labelStyle,
                    softWrap: true,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
        if (!_isOverflowing(constraints)) {
          return text;
        }
        return MouseRegion(
          onEnter: _onEnter,
          onHover: _onHover,
          onExit: _onExit,
          child: text,
        );
      },
    );
  }
}
