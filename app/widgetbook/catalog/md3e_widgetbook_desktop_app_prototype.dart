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
      child: DesktopShell(
        height: shellHeight,
        initialRailExtended: false,
        surfaceRoles: DesktopShellSurfaceRoles.lab(scheme),
        paneBuilder: _paneForNavigation,
      ),
    );
  }

  static Widget _paneForNavigation(
    BuildContext context,
    ShellNavigationSnapshot navigation,
  ) {
    switch (navigation.destinationIndex) {
      case ShellNavigation.homeDestinationIndex:
        return const HomePageLabHost();
      case ShellNavigation.libraryDestinationIndex:
        return _Md3eLibraryBrowsePagePreview(
          libraryDisplayName: navigation.selectedLibraryDisplayName,
        );
      case ShellNavigation.settingsDestinationIndex:
        return SettingsPageLabHost(
          onBack: navigation.onBackToPreviousDestination,
        );
      default:
        return const HomePageLabHost();
    }
  }
}
