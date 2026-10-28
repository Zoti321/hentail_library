import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/patterns/desktop/md3e_shell_library_secondary_layout.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Narrow library picker for compact shell (expanded rail width, not legacy 360dp drawer).
abstract final class Md3eShellCompactLibrarySheetMetrics {
  static const double width = 256;
}

class Md3eShellCompactLibrarySheet extends StatelessWidget {
  const Md3eShellCompactLibrarySheet({
    super.key,
    required this.open,
    required this.libraryDisplayNames,
    required this.selectedDisplayName,
    required this.onDismiss,
    required this.onLibrarySelected,
  });

  final bool open;
  final List<String> libraryDisplayNames;
  final String selectedDisplayName;
  final VoidCallback onDismiss;
  final ValueChanged<String> onLibrarySelected;

  @override
  Widget build(BuildContext context) {
    if (!open) {
      return const SizedBox.shrink();
    }

    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;

    return Stack(
      children: <Widget>[
        ModalBarrier(
          color: scheme.scrim.withValues(alpha: 0.32),
          onDismiss: onDismiss,
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Material(
            color: scheme.surfaceContainerLow,
            elevation: M3EElevation.level1,
            child: SizedBox(
              width: Md3eShellCompactLibrarySheetMetrics.width,
              height: MediaQuery.sizeOf(context).height,
              child: SafeArea(
                child: ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: theme.spacing.md,
                    vertical: theme.spacing.md,
                  ),
                  children: <Widget>[
                    for (final String name in libraryDisplayNames)
                      _Md3eShellCompactLibraryRow(
                        label: name,
                        selected: name == selectedDisplayName,
                        onTap: () {
                          onLibrarySelected(name);
                          onDismiss();
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Md3eShellCompactLibraryRow extends StatelessWidget {
  const _Md3eShellCompactLibraryRow({
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
