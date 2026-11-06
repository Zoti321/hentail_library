import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/widgets/desktop/window_manager_bindings.dart';
import 'package:window_manager/window_manager.dart';

/// Handles native window-close requests for the desktop shell.
///
/// `main.dart` sets `preventClose(true)`; without a listener the OS close
/// button / Alt+F4 would be swallowed. This widget closes the window on request.
class WindowCloseListener extends StatefulWidget {
  const WindowCloseListener({super.key, required this.child});

  final Widget child;

  @override
  State<WindowCloseListener> createState() => _WindowCloseListenerState();
}

class _WindowCloseListenerState extends State<WindowCloseListener>
    with WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() {
    windowManagerClose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
