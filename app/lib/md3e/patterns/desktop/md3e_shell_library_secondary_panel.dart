import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/patterns/desktop/md3e_shell_library_picker_row.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_library_dashboard_models.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Docked library picker (Lab): [Md3eLabLibraryCatalog] rows.
class Md3eShellLibrarySecondaryPanel extends StatelessWidget {
  const Md3eShellLibrarySecondaryPanel({
    super.key,
    required this.libraries,
    required this.selectedLibraryId,
    required this.onLibrarySelected,
    this.backgroundColor,
  });

  final List<Md3eHomeLibraryDashboardRow> libraries;
  final String selectedLibraryId;
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
            for (final Md3eHomeLibraryDashboardRow row in libraries)
              Md3eShellLibraryPickerRow(
                row: row,
                selected: row.libraryId == selectedLibraryId,
                onTap: () => onLibrarySelected(row.libraryId),
              ),
          ],
        ),
      ),
    );
  }
}
