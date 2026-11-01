import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/util/utils.dart';
import 'package:hentai_library/md3e/widgets/desktop/md3e_desktop_title_bar.dart';
import 'package:hentai_library/md3e/widgets/desktop/md3e_desktop_title_bar_metrics.dart';
import 'package:hentai_library/shared/ui/layout/app_layout_breakpoints.dart';
import 'package:hentai_library/shared/ui/shell/app_shell_sidebar_slot.dart';
import 'package:hentai_library/shared/ui/widgets/navigation/desktop_sidebar.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

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
            constraints.maxHeight >= Md3eDesktopTitleBarMetrics.height;

        final double sidebarRailWidth = showSidebarRail
            ? (sidebarExpanded
                  ? DesktopSidebar.expandedWidth
                  : DesktopSidebar.collapsedWidth)
            : 0;

        return Scaffold(
          key: appShellScaffoldKey,
          backgroundColor: M3ETheme.of(context).colorScheme.surfaceContainerLow,
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
                  showNavigationMenu: useDrawer && !hideAppSidebar,
                  sidebarRailWidth: sidebarRailWidth,
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
    required this.showNavigationMenu,
    required this.sidebarRailWidth,
  });

  final bool isReaderRoute;
  final bool isReaderFullscreen;
  final bool showNavigationMenu;
  final double sidebarRailWidth;

  @override
  Widget build(BuildContext context) {
    if (isReaderRoute) {
      if (isReaderFullscreen) {
        return const SizedBox.shrink();
      }
      if (supportsDesktopWindowChrome) {
        return const Md3eDesktopTitleBar(
          railWidth: 0,
          searchWidth: 0,
          showNavigationMenu: false,
        );
      }
      return const SizedBox.shrink();
    }

    if (supportsDesktopWindowChrome) {
      return Md3eDesktopTitleBar(
        railWidth: sidebarRailWidth,
        showNavigationMenu: showNavigationMenu,
        onNavigationMenuPressed: openAppShellNavigationDrawer,
        searchWidth: isReaderRoute
            ? 0
            : Md3eDesktopTitleBarMetrics.defaultSearchWidth,
        onSearchSubmitted: isReaderRoute ? null : (String query) => _submitSearch(context, query),
      );
    }

    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: const SafeArea(bottom: false, child: SizedBox.shrink()),
    );
  }
}

void _submitSearch(BuildContext context, String query) {
  final String trimmed = query.trim();
  if (trimmed.isEmpty) {
    return;
  }
  context.go('/searched?q=${Uri.encodeQueryComponent(trimmed)}');
}
