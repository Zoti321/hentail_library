import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/app_title_bar.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/navigation/desktop_sidebar.dart';
import 'package:hentai_library/presentation/ui/shared/navigation/app_navigation.dart';

class DesktopAppShell extends ConsumerStatefulWidget {
  final Widget routeChild;
  const DesktopAppShell({super.key, required this.routeChild});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _DesktopAppShellState();
}

class _ShellTitleBar extends ConsumerWidget {
  final bool isReaderRoute;

  const _ShellTitleBar({required this.isReaderRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isReaderRoute) {
      return const AppTitleBar();
    }
    final bool readerFullscreen = ref.watch(readerWindowFullscreenProvider);
    return readerFullscreen ? const SizedBox.shrink() : const AppTitleBar();
  }
}

class _DesktopAppShellState extends ConsumerState<DesktopAppShell> {
  void _onSidebarDestinationSelected(String id) {
    AppNavigation.goToNavId(context, id);
  }

  @override
  Widget build(BuildContext context) {
    final String path = GoRouterState.of(context).uri.path;
    final String sidebarActiveId = AppNavigation.activeNavIdForPath(path);
    final bool isReaderRoute = path.startsWith('/reader');
    return Scaffold(
      body: Column(
        children: <Widget>[
          _ShellTitleBar(isReaderRoute: isReaderRoute),
          Expanded(
            child: isReaderRoute
                ? widget.routeChild
                : Row(
                    children: <Widget>[
                      DesktopSidebar(
                        activeId: sidebarActiveId,
                        onDestinationSelected: _onSidebarDestinationSelected,
                      ),
                      Expanded(child: widget.routeChild),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
