import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/shared/ui/patterns/home/home_library_dashboard_models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

class HomeLibraryRowMoreMenu extends StatelessWidget {
  const HomeLibraryRowMoreMenu({
    super.key,
    required this.l10n,
    required this.row,
    this.onAction,
  });

  final AppLocalizations l10n;
  final HomeLibraryDashboardRow row;
  final ValueChanged<HomeLibraryManagementAction>? onAction;

  @override
  Widget build(BuildContext context) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final bool menuEnabled = onAction != null;
    final bool scanEnabled = menuEnabled && !row.busy;

    void emit(HomeLibraryManagementAction action) {
      onAction?.call(action);
    }

    final List<M3EMenuEntry> entries = <M3EMenuEntry>[
      M3EMenuEntry(
        label: l10n.sidebarScanLibrary,
        enabled: scanEnabled,
        onPressed: scanEnabled
            ? () => emit(HomeLibraryManagementAction.scan)
            : null,
      ),
      M3EMenuEntry(
        label: l10n.sidebarDeepScanLibrary,
        enabled: scanEnabled,
        onPressed: scanEnabled
            ? () => emit(HomeLibraryManagementAction.deepScan)
            : null,
      ),
      M3EMenuEntry(
        label: l10n.refreshMetadata,
        enabled: menuEnabled && !row.metadataRefreshInProgress,
        onPressed: menuEnabled && !row.metadataRefreshInProgress
            ? () => emit(HomeLibraryManagementAction.refreshMetadata)
            : null,
      ),
      M3EMenuEntry(
        label: row.kind == HomeLibraryKind.remote
            ? l10n.sidebarEditLibraryConnection
            : l10n.sidebarEditLibrary,
        enabled: menuEnabled,
        onPressed: menuEnabled
            ? () => emit(HomeLibraryManagementAction.edit)
            : null,
      ),
      M3EMenuEntry(
        label: l10n.sidebarDeleteLibrary,
        leading: Icon(LucideIcons.trash2, color: scheme.error),
        isDestructive: true,
        enabled: menuEnabled,
        onPressed: menuEnabled
            ? () => emit(HomeLibraryManagementAction.delete)
            : null,
      ),
    ];

    return AnchoredMenu(
      enabled: menuEnabled,
      position: M3EMenuAnchorPosition.bottomEnd,
      children: entries,
      anchorBuilder: (BuildContext context, VoidCallback open) {
        return M3EIconButton(
          icon: Icon(Icons.more_vert, color: scheme.onSurfaceVariant),
          variant: M3EIconButtonVariant.standard,
          size: M3EIconButtonSize.md,
          tooltip: l10n.metadataMoreActions,
          semanticLabel: l10n.metadataMoreActions,
          onPressed: menuEnabled ? open : null,
        );
      },
    );
  }
}
