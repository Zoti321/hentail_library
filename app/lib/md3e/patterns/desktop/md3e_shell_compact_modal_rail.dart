import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/widgets/desktop/md3e_navigation_rail.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Modal expanded navigation rail scoped to the shell (not [Overlay.rootOverlay]).
///
/// [M3ENavigationRailModality.modal] inserts at the app root, which misaligns in
/// Widgetbook [ViewportAddon] previews; this overlay stays inside [Md3eDesktopShell].
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
  });

  final bool open;
  final double height;
  final M3EThemeData m3eTheme;
  final Color surfaceBackground;
  final List<Md3eNavigationRailDestination> destinations;
  final int selectedIndex;
  final VoidCallback onDismiss;
  final ValueChanged<int> onDestinationSelected;

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
                child: Md3eNavigationRail(
                  destinations: destinations,
                  selectedIndex: selectedIndex,
                  extended: true,
                  onDestinationSelected: onDestinationSelected,
                  onMenuPressed: onDismiss,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
