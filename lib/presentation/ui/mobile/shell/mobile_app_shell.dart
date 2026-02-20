import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/presentation/ui/shared/navigation/app_navigation.dart';

class MobileAppShell extends StatefulWidget {
  final Widget routeChild;
  const MobileAppShell({super.key, required this.routeChild});

  @override
  State<MobileAppShell> createState() => _MobileAppShellState();
}

class _MobileAppShellState extends State<MobileAppShell> {
  static const List<String> _barNavIds = <String>[
    AppNavigation.navIdLibrary,
    AppNavigation.navIdHistory,
    AppNavigation.navIdManage,
    AppNavigation.navIdSettings,
  ];

  @override
  Widget build(BuildContext context) {
    final String path = GoRouterState.of(context).uri.path;
    final bool isReaderRoute = path.startsWith('/reader');
    if (isReaderRoute) {
      return widget.routeChild;
    }
    final String activeBarId = AppNavigation.mobileBarNavIdForPath(path);
    final int selectedIndex = _indexForBarId(activeBarId);
    return Scaffold(
      body: SafeArea(child: widget.routeChild),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (int index) =>
            _onDestinationSelected(context, index),
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            selectedIcon: Icon(Icons.photo_library),
            label: '漫画库',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: '历史',
          ),
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: '管理',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }

  int _indexForBarId(String id) {
    final int index = _barNavIds.indexOf(id);
    if (index >= 0) {
      return index;
    }
    return 0;
  }

  void _onDestinationSelected(BuildContext context, int index) {
    final String id = _barNavIds[index];
    AppNavigation.goToNavId(context, id);
  }
}
