import 'package:flutter/material.dart';

/// Vertical placement relative to the anchor, matching Material [PopupMenuPosition].
enum AnchoredOverlayMenuPosition {
  /// Menu top aligns with the anchor top (+ [AnchoredOverlayMenu.offset]).
  over,

  /// Menu top aligns with the anchor bottom (+ [AnchoredOverlayMenu.offset]).
  under,
}

/// Controls show/hide for [AnchoredOverlayMenu].
class AnchoredOverlayMenuController extends ChangeNotifier {
  bool _menuIsShowing = false;

  bool get menuIsShowing => _menuIsShowing;

  void showMenu() {
    if (_menuIsShowing) {
      return;
    }
    _menuIsShowing = true;
    notifyListeners();
  }

  void hideMenu() {
    if (!_menuIsShowing) {
      return;
    }
    _menuIsShowing = false;
    notifyListeners();
  }

  void toggleMenu() {
    _menuIsShowing = !_menuIsShowing;
    notifyListeners();
  }
}

/// Builds [RelativeRect] of the anchor in the [overlay]'s coordinate space.
///
/// Uses `localToGlobal(..., ancestor: overlay)` like Material [PopupMenuButton],
/// so sidebar / nested layout offsets are not double-counted.
RelativeRect anchoredOverlayMenuRect({
  required RenderBox button,
  required RenderBox overlay,
  required AnchoredOverlayMenuPosition position,
  Offset offset = Offset.zero,
}) {
  final Offset effectiveOffset = switch (position) {
    AnchoredOverlayMenuPosition.over => offset,
    AnchoredOverlayMenuPosition.under =>
      Offset(0, button.size.height) + offset,
  };
  return RelativeRect.fromRect(
    Rect.fromPoints(
      button.localToGlobal(effectiveOffset, ancestor: overlay),
      button.localToGlobal(
        button.size.bottomRight(Offset.zero) + effectiveOffset,
        ancestor: overlay,
      ),
    ),
    Offset.zero & overlay.size,
  );
}

/// Material [_PopupMenuRouteLayout] horizontal + clamp rules (simplified).
Offset resolveAnchoredOverlayMenuOffset({
  required RelativeRect anchor,
  required Size overlaySize,
  required Size menuSize,
  required TextDirection textDirection,
  EdgeInsets padding = EdgeInsets.zero,
  double screenPadding = 8,
}) {
  final double y = anchor.top;
  final double x;
  if (anchor.left > anchor.right) {
    x = overlaySize.width - anchor.right - menuSize.width;
  } else if (anchor.left < anchor.right) {
    x = anchor.left;
  } else {
    x = switch (textDirection) {
      TextDirection.rtl => overlaySize.width - anchor.right - menuSize.width,
      TextDirection.ltr => anchor.left,
    };
  }

  final Rect screen = Offset.zero & overlaySize;
  double fittedX = x;
  double fittedY = y;
  if (fittedX < screen.left + screenPadding + padding.left) {
    fittedX = screen.left + screenPadding + padding.left;
  } else if (fittedX + menuSize.width >
      screen.right - screenPadding - padding.right) {
    fittedX =
        screen.right - menuSize.width - screenPadding - padding.right;
  }
  if (fittedY < screen.top + screenPadding + padding.top) {
    fittedY = screenPadding + padding.top;
  } else if (fittedY + menuSize.height >
      screen.bottom - screenPadding - padding.bottom) {
    fittedY =
        screen.bottom - menuSize.height - screenPadding - padding.bottom;
  }
  return Offset(fittedX, fittedY);
}

/// Anchor-relative overlay menu with Material-style coordinate conversion.
///
/// Prefer this over `custom_pop_up_menu` when the trigger sits beside a
/// resizable sidebar: that package maps window-global points into a centered
/// layout and misplaces menus when content is inset.
///
/// Uses [State] for [OverlayEntry] lifecycle (accepted overlay exception).
class AnchoredOverlayMenu extends StatefulWidget {
  const AnchoredOverlayMenu({
    super.key,
    required this.menuBuilder,
    required this.child,
    this.controller,
    this.position = AnchoredOverlayMenuPosition.under,
    this.offset = Offset.zero,
    this.barrierColor = Colors.transparent,
    this.screenPadding = 8,
  });

  final Widget Function(VoidCallback hideMenu) menuBuilder;
  final Widget child;
  final AnchoredOverlayMenuController? controller;
  final AnchoredOverlayMenuPosition position;
  final Offset offset;
  final Color barrierColor;
  final double screenPadding;

  @override
  State<AnchoredOverlayMenu> createState() => _AnchoredOverlayMenuState();
}

class _AnchoredOverlayMenuState extends State<AnchoredOverlayMenu> {
  AnchoredOverlayMenuController? _ownedController;
  OverlayEntry? _entry;

  AnchoredOverlayMenuController get _controller =>
      widget.controller ?? _ownedController!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _ownedController = AnchoredOverlayMenuController();
    }
    _controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant AnchoredOverlayMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _ownedController)?.removeListener(
        _onControllerChanged,
      );
      if (widget.controller == null) {
        _ownedController ??= AnchoredOverlayMenuController();
      } else {
        _ownedController?.dispose();
        _ownedController = null;
      }
      _controller.addListener(_onControllerChanged);
      _syncOverlay();
      return;
    }
    // Refresh open menu content (e.g. enabled flags) without remeasuring.
    _entry?.markNeedsBuild();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _removeEntry();
    _ownedController?.dispose();
    super.dispose();
  }

  void _onControllerChanged() => _syncOverlay();

  void _syncOverlay() {
    if (_controller.menuIsShowing) {
      _showEntry();
    } else {
      _removeEntry();
    }
  }

  void _hideMenu() => _controller.hideMenu();

  void _removeEntry() {
    _entry?.remove();
    _entry = null;
  }

  void _showEntry() {
    final OverlayState? overlayState = Overlay.maybeOf(context);
    final RenderObject? buttonRo = context.findRenderObject();
    if (overlayState == null || buttonRo is! RenderBox || !buttonRo.hasSize) {
      _controller.hideMenu();
      return;
    }
    final RenderObject? overlayRo = overlayState.context.findRenderObject();
    if (overlayRo is! RenderBox) {
      _controller.hideMenu();
      return;
    }

    // Rebuild entry each show so anchor is measured in overlay space now
    // (sidebar width may have changed since last open).
    _removeEntry();

    final RelativeRect anchor = anchoredOverlayMenuRect(
      button: buttonRo,
      overlay: overlayRo,
      position: widget.position,
      offset: widget.offset,
    );
    final TextDirection textDirection = Directionality.of(context);
    final EdgeInsets padding = MediaQuery.paddingOf(context);

    _entry = OverlayEntry(
      builder: (BuildContext overlayContext) {
        return Stack(
          children: <Widget>[
            Positioned.fill(
              child: Listener(
                // Opaque so dismiss does not fall through to the trigger
                // (which would toggle the menu open again).
                behavior: HitTestBehavior.opaque,
                onPointerDown: (_) => _hideMenu(),
                child: ColoredBox(color: widget.barrierColor),
              ),
            ),
            CustomSingleChildLayout(
              delegate: _AnchoredOverlayMenuLayout(
                anchor: anchor,
                textDirection: textDirection,
                padding: padding,
                screenPadding: widget.screenPadding,
              ),
              child: Material(
                color: Colors.transparent,
                child: widget.menuBuilder(_hideMenu),
              ),
            ),
          ],
        );
      },
    );
    overlayState.insert(_entry!);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _AnchoredOverlayMenuLayout extends SingleChildLayoutDelegate {
  const _AnchoredOverlayMenuLayout({
    required this.anchor,
    required this.textDirection,
    required this.padding,
    required this.screenPadding,
  });

  final RelativeRect anchor;
  final TextDirection textDirection;
  final EdgeInsets padding;
  final double screenPadding;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints.loose(
      constraints.biggest,
    ).deflate(EdgeInsets.all(screenPadding) + padding);
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    return resolveAnchoredOverlayMenuOffset(
      anchor: anchor,
      overlaySize: size,
      menuSize: childSize,
      textDirection: textDirection,
      padding: padding,
      screenPadding: screenPadding,
    );
  }

  @override
  bool shouldRelayout(covariant _AnchoredOverlayMenuLayout oldDelegate) {
    return anchor != oldDelegate.anchor ||
        textDirection != oldDelegate.textDirection ||
        padding != oldDelegate.padding ||
        screenPadding != oldDelegate.screenPadding;
  }
}
