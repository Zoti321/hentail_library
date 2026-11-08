import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/util/utils.dart';
import 'package:hentai_library/shared/ui/widgets/desktop/desktop_title_bar.dart';
import 'package:hentai_library/shared/ui/widgets/desktop/desktop_title_bar_metrics.dart';
import 'package:hentai_library/shared/ui/widgets/desktop/window_close_listener.dart';
import 'package:hentai_library/shared/ui/shell/desktop_shell.dart';
import 'package:hentai_library/shared/ui/shell/desktop_shell_surfaces.dart';
import 'package:hentai_library/shared/ui/shell/app_shell_slot.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

export 'package:hentai_library/shared/ui/layout/app_shell_navigation.dart';
export 'package:hentai_library/shared/ui/shell/app_shell_sidebar_slot.dart';
export 'package:hentai_library/shared/ui/shell/app_shell_slot.dart';

/// 壳层 [DesktopShell] 的 GlobalKey（兼容旧「打开抽屉」API）。
final GlobalKey<DesktopShellState> appShellDesktopShellKey =
    GlobalKey<DesktopShellState>();

/// 兼容旧 provider：medium- 已改用底部导航，此回调为空操作。
void openAppShellNavigationDrawer() {
  appShellDesktopShellKey.currentState?.openNavigationRail();
}

/// App shell：MD3E 桌面壳（expanded+ rail / medium- 底部导航）或阅读器路由的标题栏，外加路由正文。
///
/// 壳层级反馈通过 [shellFeedbackBelowTitleBar] 注入。
class ResponsiveAppShell extends StatelessWidget {
  const ResponsiveAppShell({
    super.key,
    required this.routeChild,
    required this.isDesktopSidebarExpanded,
    required this.onToggleDesktopSidebarExpanded,
    required this.isReaderFullscreen,
    required this.navigationSlotBuilder,
    this.shellFeedbackBelowTitleBar = const <Widget>[],
  });

  final Widget routeChild;
  final bool isDesktopSidebarExpanded;
  final VoidCallback onToggleDesktopSidebarExpanded;
  final bool isReaderFullscreen;
  final AppShellNavigationSlotBuilder navigationSlotBuilder;
  final List<Widget> shellFeedbackBelowTitleBar;

  Widget _buildDesktopShell(BuildContext context, AppShellNavigationSlot slot) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final DesktopShellSurfaceRoles surfaces =
        slot.surfaceRoles ?? DesktopShellSurfaceRoles.toneBased(scheme);

    return DesktopShell(
      key: appShellDesktopShellKey,
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
      compactShowsWindowControls: supportsDesktopWindowChrome,
      paneChild: routeChild,
    );
  }

  @override
  Widget build(BuildContext context) {
    final String path = GoRouterState.of(context).uri.path;
    // 阅读器路由不显示壳层导航；其余路由（含设置）都运行在 MD3E 壳内。
    final bool isReaderRoute = path.startsWith('/reader');

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool showShellChrome =
            constraints.maxHeight >= DesktopTitleBarMetrics.height;

        final Widget body = isReaderRoute
            ? Column(
                children: <Widget>[
                  if (showShellChrome &&
                      !isReaderFullscreen &&
                      supportsDesktopWindowChrome)
                    const DesktopTitleBar(),
                  if (showShellChrome) ...shellFeedbackBelowTitleBar,
                  Expanded(child: routeChild),
                ],
              )
            : _buildDesktopShell(context, navigationSlotBuilder(context));

        return WindowCloseListener(
          child: Scaffold(
            backgroundColor: labBrowseCanvasColor(
              M3ETheme.of(context).colorScheme,
            ),
            body: body,
          ),
        );
      },
    );
  }
}
