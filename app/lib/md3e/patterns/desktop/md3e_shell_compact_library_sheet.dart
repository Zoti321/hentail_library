import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/patterns/desktop/md3e_shell_library_picker_row.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_library_dashboard_models.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Narrow library picker for compact shell (expanded rail width, not legacy 360dp drawer).
abstract final class Md3eShellCompactLibrarySheetMetrics {
  static const double width = 256;
}

class Md3eShellCompactLibrarySheet extends StatelessWidget {
  const Md3eShellCompactLibrarySheet({
    super.key,
    required this.open,
    required this.libraries,
    required this.selectedLibraryId,
    required this.onDismiss,
    required this.onLibrarySelected,
  });

  final bool open;
  final List<Md3eHomeLibraryDashboardRow> libraries;
  final String selectedLibraryId;
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
                    for (final Md3eHomeLibraryDashboardRow row in libraries)
                      Md3eShellLibraryPickerRow(
                        row: row,
                        selected: row.libraryId == selectedLibraryId,
                        onTap: () {
                          onLibrarySelected(row.libraryId);
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
