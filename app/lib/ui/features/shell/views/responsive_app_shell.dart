import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/util/utils.dart';
import 'package:hentai_library/domain/models/models.dart' show AppSetting;
import 'package:hentai_library/ui/core/layout/app_layout_breakpoints.dart';
import 'package:hentai_library/ui/core/widgets/chrome/app_title_bar.dart';
import 'package:hentai_library/ui/core/widgets/chrome/diagnostic_mode_banner.dart';
import 'package:hentai_library/ui/core/widgets/navigation/desktop_sidebar.dart';
import 'package:hentai_library/ui/features/shell/views/navigation/app_navigation.dart';
import 'package:hentai_library/ui/providers.dart';

enum _ShellLayoutMode { compact, medium, expanded }

final GlobalKey<ScaffoldState> appShellScaffoldKey = GlobalKey<ScaffoldState>();

void openAppShellNavigationDrawer() {
  appShellScaffoldKey.currentState?.openDrawer();
}

/// Header 汉堡与 shell 抽屉对齐：只看窗口总宽，不看侧栏右侧 content 宽。
bool appShellShowsPageNavigationMenu(BuildContext context) {
  return AppLayoutBreakpoints.isCompact(MediaQuery.sizeOf(context).width);
}

VoidCallback? appShellPageNavigationOpener(BuildContext context) {
  return appShellShowsPageNavigationMenu(context)
      ? openAppShellNavigationDrawer
      : null;
}

class ResponsiveAppShell extends ConsumerStatefulWidget {
  const ResponsiveAppShell({super.key, required this.routeChild});

  final Widget routeChild;

  @override
  ConsumerState<ResponsiveAppShell> createState() => _ResponsiveAppShellState();
}

class _ResponsiveAppShellState extends ConsumerState<ResponsiveAppShell> {
  void _onSidebarDestinationSelected(String id) {
    AppNavigation.goToNavId(context, id);
  }

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
    required String activeId,
    required bool isExpanded,
    bool showCollapseToggle = true,
    required VoidCallback onToggleExpanded,
    required ValueChanged<String> onDestinationSelected,
  }) {
    return DesktopSidebar(
      activeId: activeId,
      isExpanded: isExpanded,
      showCollapseToggle: showCollapseToggle,
      onToggleExpanded: onToggleExpanded,
      onDestinationSelected: onDestinationSelected,
    );
  }

  @override
  Widget build(BuildContext context) {
    final String path = GoRouterState.of(context).uri.path;
    final String sidebarActiveId = AppNavigation.activeNavIdForPath(path);
    final bool isReaderRoute = path.startsWith('/reader');
    final bool isSidebarExpandedPref = ref.watch(
      settingsProvider.select(
        (AsyncValue<AppSetting> asyncValue) =>
            asyncValue.asData?.value.desktopSidebarExpanded ?? true,
      ),
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final _ShellLayoutMode layoutMode = _layoutModeForWidth(
          constraints.maxWidth,
        );
        final bool useDrawer = layoutMode == _ShellLayoutMode.compact;
        final bool sidebarExpanded = switch (layoutMode) {
          _ShellLayoutMode.compact => true,
          _ShellLayoutMode.medium => false,
          _ShellLayoutMode.expanded => isSidebarExpandedPref,
        };
        final bool showSidebarRail = !isReaderRoute && !useDrawer;

        return Scaffold(
          key: appShellScaffoldKey,
          drawer: useDrawer && !isReaderRoute
              ? Drawer(
                  width: DesktopSidebar.expandedWidth,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: _buildSidebar(
                    activeId: sidebarActiveId,
                    isExpanded: true,
                    showCollapseToggle: false,
                    onToggleExpanded: () => Navigator.of(context).pop(),
                    onDestinationSelected: (String id) {
                      Navigator.of(context).pop();
                      _onSidebarDestinationSelected(id);
                    },
                  ),
                )
              : null,
          body: Column(
            children: <Widget>[
              _ShellTitleBar(isReaderRoute: isReaderRoute),
              const DiagnosticModeBanner(),
              Expanded(
                child: isReaderRoute
                    ? widget.routeChild
                    : Row(
                        children: <Widget>[
                          if (showSidebarRail)
                            _buildSidebar(
                              activeId: sidebarActiveId,
                              isExpanded: sidebarExpanded,
                              showCollapseToggle:
                                  layoutMode == _ShellLayoutMode.expanded,
                              onToggleExpanded: () {
                                if (layoutMode == _ShellLayoutMode.expanded) {
                                  ref
                                      .read(settingsProvider.notifier)
                                      .setDesktopSidebarExpanded(
                                        !isSidebarExpandedPref,
                                      );
                                }
                              },
                              onDestinationSelected:
                                  _onSidebarDestinationSelected,
                            ),
                          Expanded(child: widget.routeChild),
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

class _ShellTitleBar extends ConsumerWidget {
  const _ShellTitleBar({required this.isReaderRoute});

  final bool isReaderRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isReaderRoute) {
      final bool readerFullscreen = ref.watch(
        readerFullscreenControllerProvider,
      );
      if (readerFullscreen) {
        return const SizedBox.shrink();
      }
      if (isDesktop) {
        return const AppTitleBar();
      }
      return const SizedBox.shrink();
    }

    if (isDesktop) {
      return const AppTitleBar();
    }

    // 移动端各页自带标题与汉堡菜单；此处只占位状态栏，避免双 header。
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: const SafeArea(bottom: false, child: SizedBox.shrink()),
    );
  }
}
