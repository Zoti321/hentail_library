import 'package:flutter/widgets.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/infrastructure/window/window_close_listener.dart';
import 'package:hentai_library/infrastructure/window/window_manager_bindings.dart';
import 'package:hentai_library/shared/ui/window/app_window_title.dart';

Future<void> setAppWindowFullscreen(bool value) async {
  if (supportsDesktopWindowChrome) await windowManagerSetFullscreen(value);
}

Future<void> configurePreviewWindow() async {
  if (supportsDesktopWindowChrome) await initializeWindowManager();
}

Future<void> configureAppWindow() => configureDesktopWindow(
  title: appWindowTitle(),
  minimumSize: const Size(
    AppLayoutBreakpoints.minWindowWidth,
    AppLayoutBreakpoints.minWindowHeight,
  ),
);

/// Composition binds native window effects to the visual system's callbacks.
class AppWindowHost extends StatefulWidget {
  const AppWindowHost({super.key, required this.child});
  final Widget child;

  @override
  State<AppWindowHost> createState() => _AppWindowHostState();
}

class _AppWindowHostState extends State<AppWindowHost> {
  WindowCloseListener? _closeListener;

  @override
  void initState() {
    super.initState();
    if (supportsDesktopWindowChrome) {
      _closeListener = WindowCloseListener()..attach();
    }
  }

  @override
  void dispose() {
    _closeListener?.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!supportsDesktopWindowChrome) return widget.child;
    return DesktopWindowActions(
      onMinimize: windowManagerMinimize,
      onToggleMaximize: windowManagerToggleMaximize,
      onClose: windowManagerClose,
      onStartDragging: windowManagerStartDragging,
      child: widget.child,
    );
  }
}
