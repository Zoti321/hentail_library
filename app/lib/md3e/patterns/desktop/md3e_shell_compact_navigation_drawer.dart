import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/patterns/desktop/md3e_shell_navigation.dart';
import 'package:hentai_library/md3e/patterns/desktop/md3e_shell_library_secondary_layout.dart';
import 'package:hentai_library/md3e/widgets/desktop/md3e_navigation_rail.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

enum Md3eShellDrawerLevel { root, libraryPicker }

/// Modal navigation drawer (&lt; expanded breakpoint): root destinations + library drill-in.
class Md3eShellCompactNavigationDrawer extends StatelessWidget {
  const Md3eShellCompactNavigationDrawer({
    super.key,
    required this.open,
    required this.level,
    required this.selectedDestinationIndex,
    required this.libraryDisplayNames,
    required this.selectedLibraryDisplayName,
    required this.onDismiss,
    required this.onLevelChanged,
    required this.onDestinationSelected,
    required this.onLibrarySelected,
  });

  final bool open;
  final Md3eShellDrawerLevel level;
  final int selectedDestinationIndex;
  final List<String> libraryDisplayNames;
  final String selectedLibraryDisplayName;
  final VoidCallback onDismiss;
  final ValueChanged<Md3eShellDrawerLevel> onLevelChanged;
  final ValueChanged<int> onDestinationSelected;
  final ValueChanged<String> onLibrarySelected;

  static const double _drawerWidth = 360;

  @override
  Widget build(BuildContext context) {
    if (!open) {
      return const SizedBox.shrink();
    }

    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final AppLocalizations l10n = context.l10n;
    final List<Md3eNavigationRailDestination> destinations =
        md3eDefaultNavigationRailDestinations(l10n);

    return Stack(
      children: <Widget>[
        ModalBarrier(
          color: scheme.scrim.withValues(alpha: 0.32),
          onDismiss: onDismiss,
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Material(
            elevation: 1,
            color: scheme.surfaceContainerLow,
            child: SizedBox(
              width: _drawerWidth,
              height: MediaQuery.sizeOf(context).height,
              child: SafeArea(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: level == Md3eShellDrawerLevel.root
                      ? _Md3eShellDrawerRootPage(
                          key: const ValueKey<String>('root'),
                          destinations: destinations,
                          selectedDestinationIndex: selectedDestinationIndex,
                          onDestinationSelected: (int index) {
                            if (index ==
                                Md3eShellNavigation.libraryDestinationIndex) {
                              onLevelChanged(Md3eShellDrawerLevel.libraryPicker);
                              return;
                            }
                            onDestinationSelected(index);
                            onDismiss();
                          },
                        )
                      : _Md3eShellDrawerLibraryPage(
                          key: const ValueKey<String>('libraries'),
                          libraryDisplayNames: libraryDisplayNames,
                          selectedDisplayName: selectedLibraryDisplayName,
                          onBack: () =>
                              onLevelChanged(Md3eShellDrawerLevel.root),
                          onLibrarySelected: (String name) {
                            onLibrarySelected(name);
                            onDismiss();
                          },
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Md3eShellDrawerRootPage extends StatelessWidget {
  const _Md3eShellDrawerRootPage({
    super.key,
    required this.destinations,
    required this.selectedDestinationIndex,
    required this.onDestinationSelected,
  });

  final List<Md3eNavigationRailDestination> destinations;
  final int selectedDestinationIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacing.md,
        vertical: theme.spacing.md,
      ),
      children: <Widget>[
        for (int index = 0; index < destinations.length; index++)
          _Md3eShellDrawerDestinationTile(
            destination: destinations[index],
            selected: index == selectedDestinationIndex,
            showTrailingChevron:
                index == Md3eShellNavigation.libraryDestinationIndex,
            onTap: () => onDestinationSelected(index),
          ),
      ],
    );
  }
}

class _Md3eShellDrawerLibraryPage extends StatelessWidget {
  const _Md3eShellDrawerLibraryPage({
    super.key,
    required this.libraryDisplayNames,
    required this.selectedDisplayName,
    required this.onBack,
    required this.onLibrarySelected,
  });

  final List<String> libraryDisplayNames;
  final String selectedDisplayName;
  final VoidCallback onBack;
  final ValueChanged<String> onLibrarySelected;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final AppLocalizations l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.fromLTRB(
            theme.spacing.xs,
            theme.spacing.xs,
            theme.spacing.md,
            theme.spacing.sm,
          ),
          child: Row(
            children: <Widget>[
              M3EIconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack,
                variant: M3EIconButtonVariant.standard,
                size: M3EIconButtonSize.sm,
              ),
              Expanded(
                child: Text(
                  l10n.libraryTitle,
                  style: theme.typeScale.titleMedium,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: theme.spacing.md),
            children: <Widget>[
              for (final String name in libraryDisplayNames)
                _Md3eShellDrawerLibraryRow(
                  label: name,
                  selected: name == selectedDisplayName,
                  onTap: () => onLibrarySelected(name),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Md3eShellDrawerDestinationTile extends StatelessWidget {
  const _Md3eShellDrawerDestinationTile({
    required this.destination,
    required this.selected,
    required this.onTap,
    this.showTrailingChevron = false,
  });

  final Md3eNavigationRailDestination destination;
  final bool selected;
  final VoidCallback onTap;
  final bool showTrailingChevron;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final IconData icon = selected ? destination.selectedIcon : destination.icon;

    return Padding(
      padding: EdgeInsets.only(bottom: theme.spacing.xs),
      child: MouseRegion(
        cursor: Md3eShellNavigationCursor.interactive,
        child: Material(
          color: selected ? scheme.secondaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(28),
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: theme.spacing.lg,
                vertical: theme.spacing.md,
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    icon,
                    color: selected
                        ? scheme.onSecondaryContainer
                        : scheme.onSurfaceVariant,
                  ),
                  SizedBox(width: theme.spacing.md),
                  Expanded(
                    child: Text(
                      destination.label,
                      style: theme.typeScale.labelLarge.copyWith(
                        color: selected
                            ? scheme.onSecondaryContainer
                            : scheme.onSurface,
                      ),
                    ),
                  ),
                  if (showTrailingChevron)
                    Icon(
                      Icons.chevron_right,
                      color: scheme.onSurfaceVariant,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Md3eShellDrawerLibraryRow extends StatelessWidget {
  const _Md3eShellDrawerLibraryRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: theme.spacing.xs),
      child: MouseRegion(
        cursor: Md3eShellNavigationCursor.interactive,
        child: Material(
          color: selected ? scheme.secondaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(28),
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: theme.spacing.lg,
                vertical: theme.spacing.md,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  label,
                  style: theme.typeScale.labelLarge.copyWith(
                    color: selected
                        ? scheme.onSecondaryContainer
                        : scheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
