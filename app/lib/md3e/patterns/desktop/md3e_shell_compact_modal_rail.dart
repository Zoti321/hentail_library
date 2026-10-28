import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/patterns/desktop/md3e_shell_modal_library_secondary_pane.dart';
import 'package:hentai_library/md3e/patterns/desktop/md3e_shell_rail_library_hover_metrics.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_library_dashboard_models.dart';
import 'package:hentai_library/md3e/widgets/desktop/md3e_navigation_rail.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Modal expanded navigation rail scoped to the shell (not [Overlay.rootOverlay]).
///
/// [M3ENavigationRailModality.modal] inserts at the app root, which misaligns in
/// Widgetbook [ViewportAddon] previews; this overlay stays inside [Md3eDesktopShell].
///
/// At compact + medium (&lt; expanded), destinations with a secondary pane (漫画库) show a
/// trailing chevron; tapping drills into [Md3eShellModalLibrarySecondaryPane] with a
/// back affordance (MD3 navigation drawer pattern).
class Md3eShellCompactModalRailOverlay extends StatelessWidget {
  const Md3eShellCompactModalRailOverlay({
    super.key,
    required this.open,
    required this.height,
    required this.m3eTheme,
    required this.surfaceBackground,
    required this.destinations,
    required this.selectedIndex,
    required this.onDismiss,
    required this.onDestinationSelected,
    required this.libraryDrillInEnabled,
    required this.librarySecondaryOpen,
    required this.libraries,
    required this.selectedLibraryId,
    required this.onLibrarySecondaryBack,
    required this.onLibrarySelected,
  });

  final bool open;
  final double height;
  final M3EThemeData m3eTheme;
  final Color surfaceBackground;
  final List<Md3eNavigationRailDestination> destinations;
  final int selectedIndex;
  final VoidCallback onDismiss;
  final ValueChanged<int> onDestinationSelected;
  final bool libraryDrillInEnabled;
  final bool librarySecondaryOpen;
  final List<Md3eHomeLibraryDashboardRow> libraries;
  final String selectedLibraryId;
  final VoidCallback onLibrarySecondaryBack;
  final ValueChanged<String> onLibrarySelected;

  @override
  Widget build(BuildContext context) {
    if (!open) {
      return const SizedBox.shrink();
    }

    final M3EColorScheme scheme = m3eTheme.colorScheme;
    final M3EThemeData railTheme = m3eTheme.copyWith(
      navigationRailTheme: m3eTheme.navigationRailTheme.copyWith(
        containerColor: surfaceBackground,
      ),
    );
    final bool showLibrarySecondary =
        libraryDrillInEnabled && librarySecondaryOpen;

    return Stack(
      children: <Widget>[
        ModalBarrier(
          color: scheme.scrim.withValues(alpha: 0.32),
          onDismiss: onDismiss,
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Material(
            color: surfaceBackground,
            elevation: M3EElevation.level1,
            child: SizedBox(
              width: Md3eNavigationRailMetrics.expandedWidth,
              height: height,
              child: M3ETheme(
                data: railTheme,
                child: showLibrarySecondary
                    ? Md3eShellModalLibrarySecondaryPane(
                        libraries: libraries,
                        selectedLibraryId: selectedLibraryId,
                        backgroundColor: surfaceBackground,
                        onBack: onLibrarySecondaryBack,
                        onLibrarySelected: onLibrarySelected,
                      )
                    : _Md3eShellModalPrimaryRailBody(
                        destinations: destinations,
                        selectedIndex: selectedIndex,
                        onDestinationSelected: onDestinationSelected,
                        onMenuPressed: onDismiss,
                        libraryDrillInEnabled: libraryDrillInEnabled,
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Md3eShellModalPrimaryRailBody extends StatelessWidget {
  const _Md3eShellModalPrimaryRailBody({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onMenuPressed,
    required this.libraryDrillInEnabled,
  });

  final List<Md3eNavigationRailDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onMenuPressed;
  final bool libraryDrillInEnabled;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3ENavigationRailTheme navTheme = theme.navigationRailTheme;
    const bool railExtended = true;

    final double libraryTop = Md3eShellRailLibraryHoverMetrics.destinationTop(
      theme: navTheme,
      railExtended: railExtended,
      destinationIndex:
          Md3eShellRailLibraryHoverMetrics.libraryDestinationIndex,
    );
    final double libraryHeight =
        Md3eShellRailLibraryHoverMetrics.destinationHeight(
          theme: navTheme,
          railExtended: railExtended,
        );

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Md3eNavigationRail(
          destinations: destinations,
          selectedIndex: selectedIndex,
          extended: railExtended,
          onDestinationSelected: onDestinationSelected,
          onMenuPressed: onMenuPressed,
        ),
        if (libraryDrillInEnabled)
          Positioned(
            top: libraryTop,
            left: 0,
            right: theme.spacing.md,
            height: libraryHeight,
            child: IgnorePointer(
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
