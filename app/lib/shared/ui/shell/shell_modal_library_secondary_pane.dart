import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/shell/shell_library_secondary_panel.dart';
import 'package:hentai_library/shared/ui/shell/shell_modal_navigation_copy.dart';
import 'package:hentai_library/shared/ui/patterns/home/home_library_dashboard_models.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Library secondary level inside modal navigation (&lt; expanded, medium drill-in).
class ShellModalLibrarySecondaryPane extends StatelessWidget {
  const ShellModalLibrarySecondaryPane({
    super.key,
    required this.libraries,
    required this.selectedLibraryId,
    required this.onBack,
    required this.onLibrarySelected,
    this.backgroundColor,
  });

  final List<HomeLibraryDashboardRow> libraries;
  final String selectedLibraryId;
  final VoidCallback onBack;
  final ValueChanged<String> onLibrarySelected;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final MaterialLocalizations materialL10n = MaterialLocalizations.of(
      context,
    );

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
                      ShellModalNavigationCopy.primaryNavBackLabel,
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
            child: ShellLibrarySecondaryPanel(
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
