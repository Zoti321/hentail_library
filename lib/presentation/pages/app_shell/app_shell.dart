import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/presentation/widgets/app_title_bar.dart';
import 'package:hentai_library/presentation/widgets/desktop_sidebar.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

class AppShell extends ConsumerStatefulWidget {
  final Widget routeChild;
  const AppShell({super.key, required this.routeChild});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> with TrayListener {
  String _activeTab = 'home';

  @override
  void initState() {
    trayManager.addListener(this);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AppTitleBar(),
          Expanded(
            child: Row(
              children: [
                DesktopSidebar(
                  activeId: _activeTab,
                  onDestinationSelected: (id) {
                    setState(() {
                      _activeTab = id;
                    });
                    _onDestinationTap(id, context);
                  },
                ),
                Expanded(child: widget.routeChild),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onDestinationTap(String id, BuildContext context) {
    switch (id) {
      case 'home':
        context.go('/home');
        break;
      case 'library':
        context.go('/local');
        break;
      case 'selectedPaths':
        context.go('/paths');
        break;
      case 'tags':
        context.go('/tags');
        break;
      case 'series':
        context.go('/series');
        break;
      case 'history':
        context.go('/history');
      case 'settings':
        context.go('/settings');
        break;
    }
  }

  // 系统托盘
  @override
  onTrayIconMouseDown() async {
    await windowManager.show();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    switch (menuItem.key) {
      case 'show_window':
        await windowManager.show();
        break;
      case 'exit_app':
        await windowManager.destroy();
        break;
    }
  }
}
