import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Anchor rectangle in the same coordinate space as [showM3EMenu] (root overlay).
///
/// [M3EMenu] uses [Overlay.maybeOf] without [rootOverlay], while [showM3EMenu]
/// inserts into the root overlay — mismatched spaces misplace menus in Widgetbook.
Rect? md3eMenuAnchorRectFor(BuildContext context) {
  final RenderObject? object = context.findRenderObject();
  if (object is! RenderBox || !object.hasSize || !object.attached) {
    return null;
  }
  final OverlayState overlay = Overlay.of(context, rootOverlay: true);
  final RenderObject ancestor = overlay.context.findRenderObject()!;
  return MatrixUtils.transformRect(
    object.getTransformTo(ancestor),
    Offset.zero & object.size,
  );
}

/// Like [showM3EMenu], but re-attaches [M3ETheme] on the overlay route.
///
/// Root [OverlayEntry] builders (Widgetbook shell) can sit above the
/// [M3EMaterialApp] theme scope; without this, [M3ETheme.of] falls back to
/// [M3EThemeData.fromMaterial] and loses the lab [fontFamily].
Future<T?> md3eShowAnchoredMenu<T>({
  required BuildContext context,
  required Rect anchor,
  required List<M3EMenuNode> children,
  M3EMenuAnchorPosition position = M3EMenuAnchorPosition.bottomEnd,
  FocusNode? callerFocusNode,
}) {
  final M3EThemeData themeData = M3ETheme.of(context);
  final Completer<T?> completer = Completer<T?>();
  final ModalRoute<dynamic>? historyRoute = ModalRoute.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (BuildContext overlayContext) {
      return M3ETheme(
        data: themeData,
        child: M3EMenuPopup<T>(
          anchor: anchor,
          children: children,
          position: position,
          historyRoute: historyRoute,
          callerFocusNode: callerFocusNode,
          onSelected: (Object? value) {
            if (!completer.isCompleted) {
              completer.complete(value as T?);
            }
          },
          onDismiss: () {
            if (!completer.isCompleted) {
              completer.complete(null);
            }
          },
          onRemove: () => entry.remove(),
        ),
      );
    },
  );
  Overlay.of(context, rootOverlay: true).insert(entry);
  return completer.future;
}

/// [M3EMenu] with root-overlay anchor math (nested navigators / Widgetbook).
class Md3eAnchoredMenu extends StatefulWidget {
  const Md3eAnchoredMenu({
    super.key,
    required this.anchorBuilder,
    required this.children,
    this.position = M3EMenuAnchorPosition.bottomEnd,
    this.enabled = true,
  });

  final M3EMenuAnchorBuilder anchorBuilder;
  final List<M3EMenuNode> children;
  final M3EMenuAnchorPosition position;
  final bool enabled;

  @override
  State<Md3eAnchoredMenu> createState() => _Md3eAnchoredMenuState();
}

class _Md3eAnchoredMenuState extends State<Md3eAnchoredMenu> {
  final GlobalKey _anchorKey = GlobalKey();
  final FocusNode _anchorFocus = FocusNode(debugLabel: 'Md3eAnchoredMenu');
  bool _open = false;

  @override
  void dispose() {
    _anchorFocus.dispose();
    super.dispose();
  }

  Future<void> _openMenu() async {
    if (_open || !widget.enabled) {
      return;
    }
    final BuildContext? anchorContext = _anchorKey.currentContext;
    if (anchorContext == null) {
      return;
    }
    final Rect? anchor = md3eMenuAnchorRectFor(anchorContext);
    if (anchor == null) {
      return;
    }
    setState(() => _open = true);
    await md3eShowAnchoredMenu<void>(
      context: anchorContext,
      anchor: anchor,
      children: widget.children,
      position: widget.position,
      callerFocusNode: _anchorFocus,
    );
    if (mounted) {
      setState(() => _open = false);
    }
  }

  KeyEventResult _onAnchorKey(FocusNode node, KeyEvent event) {
    if (_open || event is! KeyDownEvent || !widget.enabled) {
      return KeyEventResult.ignored;
    }
    final LogicalKeyboardKey key = event.logicalKey;
    final bool openKey =
        key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.space;
    if (!openKey) {
      return KeyEventResult.ignored;
    }
    _openMenu();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return M3EComponentTheme(
      builder: (BuildContext context) {
        return KeyedSubtree(
          key: _anchorKey,
          child: Focus(
            focusNode: _anchorFocus,
            canRequestFocus: false,
            skipTraversal: true,
            onKeyEvent: _onAnchorKey,
            child: widget.anchorBuilder(context, _openMenu),
          ),
        );
      },
    );
  }
}
