part of 'md3e_widgetbook_directories.dart';

/// 桌面壳 + 主导航目的地，复用各 `pages/` 预览的假数据与交互。
class _Md3eLabDesktopAppPrototype extends StatelessWidget {
  const _Md3eLabDesktopAppPrototype();

  @override
  Widget build(BuildContext context) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final double viewportHeight = MediaQuery.sizeOf(context).height;
    final double shellHeight = viewportHeight >= 560 ? viewportHeight : 768;

    return Md3eWidgetbookScope(
      child: Md3eDesktopShell(
        height: shellHeight,
        initialRailExtended: false,
        surfaceRoles: Md3eDesktopShellSurfaceRoles.lab(scheme),
        paneBuilder: _paneForNavigation,
      ),
    );
  }

  static Widget _paneForNavigation(
    BuildContext context,
    Md3eShellNavigationSnapshot navigation,
  ) {
    switch (navigation.destinationIndex) {
      case Md3eShellNavigation.homeDestinationIndex:
        return const _Md3eLabHomePanePlaceholder();
      case Md3eShellNavigation.libraryDestinationIndex:
        return _Md3eLibraryBrowsePagePreview(
          libraryDisplayName: navigation.selectedLibraryDisplayName,
        );
      case Md3eShellNavigation.managementDestinationIndex:
        return const _Md3eManagementBrowsePagePreview();
      case Md3eShellNavigation.historyDestinationIndex:
        return const _Md3eHistoryBrowsePagePreview();
      case Md3eShellNavigation.settingsDestinationIndex:
        return const Md3eSettingsPage();
      default:
        return const _Md3eLabHomePanePlaceholder();
    }
  }
}

/// Lab 首页占位（生产首页尚未迁入 md3e）。
class _Md3eLabHomePanePlaceholder extends StatelessWidget {
  const _Md3eLabHomePanePlaceholder();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final M3ESpacing spacing = theme.spacing;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(spacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.home_outlined,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              SizedBox(height: spacing.lg),
              Text(
                l10n.navHome,
                style: theme.typeScale.headlineSmall.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: spacing.sm),
              Text(
                'Widgetbook：≥840dp 用侧栏 rail + hover 选库；较窄窗口用顶栏 ☰ 抽屉。',
                style: theme.typeScale.bodyMedium.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
