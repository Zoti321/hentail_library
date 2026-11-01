import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/util/utils.dart';
import 'package:hentai_library/shared/ui/widgets/desktop/desktop_title_bar.dart';
import 'package:hentai_library/shared/ui/widgets/desktop/desktop_title_bar_metrics.dart';
import 'package:hentai_library/shared/ui/widgets/desktop/window_close_listener.dart';
import 'package:hentai_library/shared/ui/layout/app_layout_breakpoints.dart';
import 'package:hentai_library/shared/ui/shell/app_shell_sidebar_slot.dart';
import 'package:hentai_library/shared/ui/shell/desktop_shell.dart';
import 'package:hentai_library/shared/ui/shell/desktop_shell_surfaces.dart';
import 'package:hentai_library/shared/ui/shell/md3e_app_shell_slot.dart';
import 'package:hentai_library/shared/ui/widgets/navigation/desktop_sidebar.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

export 'package:hentai_library/shared/ui/layout/app_shell_navigation.dart';
export 'package:hentai_library/shared/ui/shell/app_shell_sidebar_slot.dart';
export 'package:hentai_library/shared/ui/shell/md3e_app_shell_slot.dart';

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
    required this.md3eNavigationSlotBuilder,
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
  final Md3eAppShellNavigationSlotBuilder md3eNavigationSlotBuilder;
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

  Widget _buildMd3eDesktopShell(
    BuildContext context,
    Md3eAppShellNavigationSlot slot,
  ) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final Md3eDesktopShellSurfaceRoles surfaces =
        slot.surfaceRoles ?? Md3eDesktopShellSurfaceRoles.toneBased(scheme);

    return Md3eDesktopShell(
      fillHeight: true,
      railDestinations: slot.railDestinations,
      libraries: slot.libraries,
      selectedNavId: slot.selectedNavId,
      selectedLibraryId: slot.selectedLibraryId,
      onNavIdSelected: slot.onNavIdSelected,
      onLibrarySelected: slot.onLibrarySelected,
      railExtended: isDesktopSidebarExpanded,
      onRailExtendedToggle: onToggleDesktopSidebarExpanded,
      surfaceRoles: surfaces,
      belowTitleBar: shellFeedbackBelowTitleBar,
      onSearchSubmitted: (String query) => _submitSearch(context, query),
      paneChild: routeChild,
    );
  }

  @override
  Widget build(BuildContext context) {
    final String path = GoRouterState.of(context).uri.path;
    final String sidebarActiveId = activeNavIdForPath(path);
    final bool isReaderRoute = path.startsWith('/reader');
    // 设置页与其他目的地一样运行在壳内（rail 选中“设置”，内容为圆角 pane）。
    final bool hideAppSidebar = isReaderRoute;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final _ShellLayoutMode layoutMode = _layoutModeForWidth(
          constraints.maxWidth,
        );
        final bool useDrawer = layoutMode == _ShellLayoutMode.compact;
        final bool useMd3eDesktopChrome = !useDrawer && !hideAppSidebar;
        final bool sidebarExpanded = switch (layoutMode) {
          _ShellLayoutMode.compact => true,
          _ShellLayoutMode.medium ||
          _ShellLayoutMode.expanded => isDesktopSidebarExpanded,
        };
        final bool showShellChrome =
            constraints.maxHeight >= Md3eDesktopTitleBarMetrics.height;

        final double sidebarRailWidth = useDrawer || useMd3eDesktopChrome
            ? 0
            : (sidebarExpanded
                  ? DesktopSidebar.expandedWidth
                  : DesktopSidebar.collapsedWidth);

        final Widget body = hideAppSidebar
            ? routeChild
            : useMd3eDesktopChrome
            ? _buildMd3eDesktopShell(
                context,
                md3eNavigationSlotBuilder(context),
              )
            : Row(
                children: <Widget>[
                  _buildSidebar(
                    activeNavId: sidebarActiveId,
                    isExpanded: sidebarExpanded,
                    showCollapseToggle: !useDrawer,
                    allowLibraryReorder: !useDrawer && sidebarExpanded,
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
              );

        return Md3eWindowCloseListener(
          child: Scaffold(
            key: appShellScaffoldKey,
            backgroundColor: M3ETheme.of(context)
                .colorScheme
                .surfaceContainerLow,
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
            body: useMd3eDesktopChrome
                ? body
                : Column(
                    children: <Widget>[
                      if (showShellChrome)
                        _ShellTitleBar(
                          isReaderRoute: isReaderRoute,
                          isReaderFullscreen: isReaderFullscreen,
                          showNavigationMenu: useDrawer && !hideAppSidebar,
                          sidebarRailWidth: sidebarRailWidth,
                        ),
                      if (showShellChrome) ...shellFeedbackBelowTitleBar,
                      Expanded(child: body),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

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
        onSearchSubmitted: isReaderRoute
            ? null
            : (String query) => _submitSearch(context, query),
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
