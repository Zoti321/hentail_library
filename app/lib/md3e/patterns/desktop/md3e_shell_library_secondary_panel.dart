import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/patterns/desktop/md3e_shell_library_secondary_layout.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Docked library picker (Lab v0): mock display names only.
class Md3eShellLibrarySecondaryPanel extends StatelessWidget {
  const Md3eShellLibrarySecondaryPanel({
    super.key,
    required this.libraryDisplayNames,
    required this.selectedDisplayName,
    required this.onLibrarySelected,
    this.backgroundColor,
  });

  final List<String> libraryDisplayNames;
  final String selectedDisplayName;
  final ValueChanged<String> onLibrarySelected;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;

    return ColoredBox(
      color: backgroundColor ?? scheme.surfaceContainer,
      child: SafeArea(
        right: false,
        child: ListView(
          padding: EdgeInsets.symmetric(
            horizontal: theme.spacing.md,
            vertical: theme.spacing.sm,
          ),
          children: <Widget>[
            for (final String name in libraryDisplayNames)
              _Md3eShellLibrarySecondaryRow(
                label: name,
                selected: name == selectedDisplayName,
                onTap: () => onLibrarySelected(name),
              ),
          ],
        ),
      ),
    );
  }
}

class _Md3eShellLibrarySecondaryRow extends StatelessWidget {
  const _Md3eShellLibrarySecondaryRow({
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.typeScale.labelLarge.copyWith(
                    color: selected
                        ? scheme.onSecondaryContainer
                        : scheme.onSurface,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
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
