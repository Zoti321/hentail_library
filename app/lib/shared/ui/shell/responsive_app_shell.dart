import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/util/utils.dart';
import 'package:hentai_library/shared/ui/widgets/desktop/desktop_title_bar.dart';
import 'package:hentai_library/shared/ui/widgets/desktop/desktop_title_bar_metrics.dart';
import 'package:hentai_library/shared/ui/widgets/desktop/window_close_listener.dart';
import 'package:hentai_library/shared/ui/shell/desktop_shell.dart';
import 'package:hentai_library/shared/ui/shell/desktop_shell_surfaces.dart';
import 'package:hentai_library/shared/ui/shell/md3e_app_shell_slot.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

export 'package:hentai_library/shared/ui/layout/app_shell_navigation.dart';
export 'package:hentai_library/shared/ui/shell/app_shell_sidebar_slot.dart';
export 'package:hentai_library/shared/ui/shell/md3e_app_shell_slot.dart';

/// 壳层外部（页头菜单等）通过此 key 打开 MD3E 紧凑导航。
final GlobalKey<Md3eDesktopShellState> appShellDesktopShellKey =
    GlobalKey<Md3eDesktopShellState>();

/// 打开紧凑（< expanded）导航：即 [Md3eDesktopShell] 的 modal rail。名称保留以兼容既有 provider。
void openAppShellNavigationDrawer() {
  appShellDesktopShellKey.currentState?.openNavigationRail();
}

/// App shell：MD3E 桌面壳（rail / 紧凑 modal 导航）或阅读器路由的标题栏，外加路由正文。
///
/// 壳层级反馈通过 [shellFeedbackBelowTitleBar] 注入。
class ResponsiveAppShell extends StatelessWidget {
  const ResponsiveAppShell({
    super.key,
    required this.routeChild,
    required this.isDesktopSidebarExpanded,
    required this.onToggleDesktopSidebarExpanded,
    required this.isReaderFullscreen,
    required this.md3eNavigationSlotBuilder,
    this.shellFeedbackBelowTitleBar = const <Widget>[],
  });

  final Widget routeChild;
  final bool isDesktopSidebarExpanded;
  final VoidCallback onToggleDesktopSidebarExpanded;
  final bool isReaderFullscreen;
  final Md3eAppShellNavigationSlotBuilder md3eNavigationSlotBuilder;
  final List<Widget> shellFeedbackBelowTitleBar;

  Widget _buildMd3eDesktopShell(
    BuildContext context,
    Md3eAppShellNavigationSlot slot,
  ) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final Md3eDesktopShellSurfaceRoles surfaces =
        slot.surfaceRoles ?? Md3eDesktopShellSurfaceRoles.toneBased(scheme);

    return Md3eDesktopShell(
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
            constraints.maxHeight >= Md3eDesktopTitleBarMetrics.height;

        final Widget body = isReaderRoute
            ? Column(
                children: <Widget>[
                  if (showShellChrome &&
                      !isReaderFullscreen &&
                      supportsDesktopWindowChrome)
                    const Md3eDesktopTitleBar(),
                  if (showShellChrome) ...shellFeedbackBelowTitleBar,
                  Expanded(child: routeChild),
                ],
              )
            : _buildMd3eDesktopShell(
                context,
                md3eNavigationSlotBuilder(context),
              );

        return Md3eWindowCloseListener(
          child: Scaffold(
            backgroundColor: md3eLabBrowseCanvasColor(
              M3ETheme.of(context).colorScheme,
            ),
            body: body,
          ),
        );
      },
    );
  }
}
