import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/patterns/desktop/md3e_shell_library_secondary_panel.dart';
import 'package:hentai_library/md3e/patterns/desktop/md3e_shell_modal_navigation_copy.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_library_dashboard_models.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Library secondary level inside modal navigation (&lt; expanded, medium drill-in).
class Md3eShellModalLibrarySecondaryPane extends StatelessWidget {
  const Md3eShellModalLibrarySecondaryPane({
    super.key,
    required this.libraries,
    required this.selectedLibraryId,
    required this.onBack,
    required this.onLibrarySelected,
    this.backgroundColor,
  });

  final List<Md3eHomeLibraryDashboardRow> libraries;
  final String selectedLibraryId;
  final VoidCallback onBack;
  final ValueChanged<String> onLibrarySelected;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final MaterialLocalizations materialL10n = MaterialLocalizations.of(context);

    return ColoredBox(
      color: backgroundColor ?? scheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                theme.spacing.xs,
                theme.spacing.sm,
                theme.spacing.md,
                theme.spacing.xs,
              ),
              child: Row(
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    tooltip: materialL10n.backButtonTooltip,
                    onPressed: onBack,
                  ),
                  Expanded(
                    child: Text(
                      Md3eShellModalNavigationCopy.primaryNavBackLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.typeScale.titleMedium.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Md3eShellLibrarySecondaryPanel(
              libraries: libraries,
              selectedLibraryId: selectedLibraryId,
              onLibrarySelected: onLibrarySelected,
              backgroundColor: backgroundColor,
            ),
          ),
        ],
      ),
    );
  }
}
