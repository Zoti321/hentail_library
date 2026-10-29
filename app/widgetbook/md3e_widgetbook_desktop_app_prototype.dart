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
        return const Md3eHomePageLabHost();
      case Md3eShellNavigation.libraryDestinationIndex:
        return _Md3eLibraryBrowsePagePreview(
          libraryDisplayName: navigation.selectedLibraryDisplayName,
        );
      case Md3eShellNavigation.managementDestinationIndex:
        return const Md3eManagementBrowsePageLabHost();
      case Md3eShellNavigation.historyDestinationIndex:
        return Md3eHistoryBrowsePageLabHost(
          clock: DateTime(2026, 6, 15, 14),
        );
      case Md3eShellNavigation.settingsDestinationIndex:
        return const Md3eSettingsPageLabHost();
      default:
        return const Md3eHomePageLabHost();
    }
  }
}
