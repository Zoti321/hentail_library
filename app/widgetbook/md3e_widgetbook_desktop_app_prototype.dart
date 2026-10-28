part of 'md3e_widgetbook_directories.dart';

/// Lab 全壳原型：同一棵树随 Viewport 在 &lt;840（modal expanded rail）与 expanded+（标准 rail）间切换。
class _Md3eLabAppPrototype extends StatelessWidget {
  const _Md3eLabAppPrototype();

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
                'Widgetbook：Viewport ≥840dp 为桌面（rail + hover 选库）；'
                '<840dp 为移动/平板（圆形 ☰ + modal expanded rail，256dp 库列）。',
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
