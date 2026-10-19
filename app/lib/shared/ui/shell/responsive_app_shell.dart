import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/util/utils.dart';
import 'package:hentai_library/shared/ui/layout/app_layout_breakpoints.dart';
import 'package:hentai_library/shared/ui/widgets/chrome/app_title_bar.dart';
import 'package:hentai_library/shared/ui/shell/app_shell_sidebar_slot.dart';
import 'package:hentai_library/shared/ui/widgets/navigation/desktop_sidebar.dart';

export 'package:hentai_library/shared/ui/layout/app_shell_navigation.dart';
export 'package:hentai_library/shared/ui/shell/app_shell_sidebar_slot.dart';

enum _ShellLayoutMode { compact, medium, expanded }

final GlobalKey<ScaffoldState> appShellScaffoldKey = GlobalKey<ScaffoldState>();

void openAppShellNavigationDrawer() {
  appShellScaffoldKey.currentState?.openDrawer();
}

/// App shell: title bar, optional global banners, sidebar/drawer, route body.
///
/// Feature-specific sidebar content and shell-level feedback are injected via
/// [sidebarBuilder] and [shellFeedbackBelowTitleBar].
class ResponsiveAppShell extends StatelessWidget {
  const ResponsiveAppShell({
    super.key,
    required this.routeChild,
    required this.activeNavIdForPath,
    required this.sidebarBuilder,
    required this.onNavDestinationSelected,
    required this.isDesktopSidebarExpanded,
    required this.onToggleDesktopSidebarExpanded,
    required this.isReaderFullscreen,
    this.shellFeedbackBelowTitleBar = const <Widget>[],
  });

  final Widget routeChild;
  final String Function(String path) activeNavIdForPath;
  final AppShellSidebarBuilder sidebarBuilder;
  final void Function(BuildContext context, String navId)
  onNavDestinationSelected;
  final bool isDesktopSidebarExpanded;
  final VoidCallback onToggleDesktopSidebarExpanded;
  final bool isReaderFullscreen;
  final List<Widget> shellFeedbackBelowTitleBar;

  _ShellLayoutMode _layoutModeForWidth(double width) {
    if (AppLayoutBreakpoints.isCompact(width)) {
      return _ShellLayoutMode.compact;
    }
    if (AppLayoutBreakpoints.isMedium(width)) {
      return _ShellLayoutMode.medium;
    }
    return _ShellLayoutMode.expanded;
  }

  Widget _buildSidebar({
    required String activeNavId,
    required bool isExpanded,
    bool showCollapseToggle = true,
    bool applyDrawerTopInset = false,
    VoidCallback? onLibrariesNavigate,
    required VoidCallback onToggleExpanded,
    required ValueChanged<String> onDestinationSelected,
    required bool allowLibraryReorder,
  }) {
    final AppShellSidebarSlot slot = (
      activeNavId: activeNavId,
      isExpanded: isExpanded,
      showCollapseToggle: showCollapseToggle,
      applyDrawerTopInset: applyDrawerTopInset,
      allowLibraryReorder: allowLibraryReorder,
      onLibrariesNavigate: onLibrariesNavigate,
      onToggleExpanded: onToggleExpanded,
      onDestinationSelected: onDestinationSelected,
    );
    return sidebarBuilder(slot);
  }

  @override
  Widget build(BuildContext context) {
    final String path = GoRouterState.of(context).uri.path;
    final String sidebarActiveId = activeNavIdForPath(path);
    final bool isReaderRoute = path.startsWith('/reader');
    final bool hideAppSidebar = isReaderRoute || _isSettingsRoute(path);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final _ShellLayoutMode layoutMode = _layoutModeForWidth(
          constraints.maxWidth,
        );
        final bool useDrawer = layoutMode == _ShellLayoutMode.compact;
        final bool sidebarExpanded = switch (layoutMode) {
          _ShellLayoutMode.compact => true,
          _ShellLayoutMode.medium ||
          _ShellLayoutMode.expanded => isDesktopSidebarExpanded,
        };
        final bool showSidebarRail = !hideAppSidebar && !useDrawer;
        final bool showShellChrome =
            constraints.maxHeight >= AppTitleBar.height;

        return Scaffold(
          key: appShellScaffoldKey,
          drawer: useDrawer && !hideAppSidebar
              ? Drawer(
                  width: DesktopSidebar.expandedWidth,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: _buildSidebar(
                    activeNavId: sidebarActiveId,
                    isExpanded: true,
                    showCollapseToggle: false,
                    applyDrawerTopInset: true,
                    allowLibraryReorder: false,
                    onLibrariesNavigate: () {
                      appShellScaffoldKey.currentState?.closeDrawer();
                    },
                    onToggleExpanded: () => Navigator.of(context).pop(),
                    onDestinationSelected: (String id) {
                      Navigator.of(context).pop();
                      onNavDestinationSelected(context, id);
                    },
                  ),
                )
              : null,
          body: Column(
            children: <Widget>[
              if (showShellChrome)
                _ShellTitleBar(
                  isReaderRoute: isReaderRoute,
                  isReaderFullscreen: isReaderFullscreen,
                ),
              if (showShellChrome) ...shellFeedbackBelowTitleBar,
              Expanded(
                child: hideAppSidebar
                    ? routeChild
                    : Row(
                        children: <Widget>[
                          if (showSidebarRail)
                            _buildSidebar(
                              activeNavId: sidebarActiveId,
                              isExpanded: sidebarExpanded,
                              showCollapseToggle: !useDrawer,
                              allowLibraryReorder:
                                  !useDrawer && sidebarExpanded,
                              onToggleExpanded: () {
                                if (!useDrawer) {
                                  onToggleDesktopSidebarExpanded();
                                }
                              },
                              onDestinationSelected: (String id) {
                                onNavDestinationSelected(context, id);
                              },
                            ),
                          Expanded(child: routeChild),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

bool _isSettingsRoute(String path) => path == '/settings';

class _ShellTitleBar extends StatelessWidget {
  const _ShellTitleBar({
    required this.isReaderRoute,
    required this.isReaderFullscreen,
  });

  final bool isReaderRoute;
  final bool isReaderFullscreen;

  @override
  Widget build(BuildContext context) {
    if (isReaderRoute) {
      if (isReaderFullscreen) {
        return const SizedBox.shrink();
      }
      if (supportsDesktopWindowChrome) {
        return const AppTitleBar();
      }
      return const SizedBox.shrink();
    }

    if (supportsDesktopWindowChrome) {
      return const AppTitleBar();
    }

    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: const SafeArea(bottom: false, child: SizedBox.shrink()),
    );
  }
}
