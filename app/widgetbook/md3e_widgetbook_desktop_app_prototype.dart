part of 'md3e_widgetbook_directories.dart';

/// 桌面壳 + 主导航目的地，复用各 `pages/` 预览的假数据与交互。
class _Md3eLabDesktopAppPrototype extends StatelessWidget {
  const _Md3eLabDesktopAppPrototype();

  static const int _homeDestinationIndex = 0;
  static const int _libraryDestinationIndex = 1;
  static const int _managementDestinationIndex = 2;
  static const int _historyDestinationIndex = 3;
  static const int _settingsDestinationIndex = 4;

  @override
  Widget build(BuildContext context) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final double viewportHeight = MediaQuery.sizeOf(context).height;
    final double shellHeight = viewportHeight >= 560 ? viewportHeight : 768;

    return Md3eWidgetbookDesktopExpandedGate(
      alignment: Alignment.topLeft,
      child: Md3eDesktopShell(
        height: shellHeight,
        initialRailExtended: false,
        surfaceRoles: Md3eDesktopShellSurfaceRoles.lab(scheme),
        paneBuilder: _paneForDestination,
      ),
    );
  }

  static Widget _paneForDestination(
    BuildContext context,
    int destinationIndex,
  ) {
    switch (destinationIndex) {
      case _homeDestinationIndex:
        return const _Md3eLabHomePanePlaceholder();
      case _libraryDestinationIndex:
        return const _Md3eLibraryBrowsePagePreview();
      case _managementDestinationIndex:
        return const _Md3eManagementBrowsePagePreview();
      case _historyDestinationIndex:
        return const _Md3eHistoryBrowsePagePreview();
      case _settingsDestinationIndex:
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
                'Widgetbook 场景预览：请用左侧导航切换到漫画库、管理、历史或设置。',
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
