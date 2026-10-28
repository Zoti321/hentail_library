import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_library_dashboard_models.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_library_management_copy.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_library_reorderable_list.dart';
import 'package:hentai_library/md3e/widgets/menu/md3e_anchored_menu.dart';
import 'package:hentai_library/md3e/widgets/settings/md3e_settings_tile.dart';
import 'package:hentai_library/md3e/widgets/settings/md3e_split_list_group.dart';
import 'package:intl/intl.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// 首页「我的漫画库」：汇总 + 可操作的库列表（Lab；数据由调用方注入）。
class Md3eHomeLibraryManagementSection extends StatelessWidget {
  const Md3eHomeLibraryManagementSection({
    super.key,
    required this.libraries,
    this.onLibraryOpen,
    this.onLibraryAction,
    this.onAddLocalLibrary,
    this.onAddRemoteLibrary,
    this.onLibrariesReorder,
  });

  final List<Md3eHomeLibraryDashboardRow> libraries;
  final ValueChanged<String>? onLibraryOpen;
  final void Function(String libraryId, Md3eHomeLibraryManagementAction action)?
      onLibraryAction;
  final VoidCallback? onAddLocalLibrary;
  final VoidCallback? onAddRemoteLibrary;

  /// 非 null 时列表可拖拽排序；顺序变更仅通过此回调上报（持久化由上层负责）。
  final void Function(int oldIndex, int newIndex)? onLibrariesReorder;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final M3ETypeScale type = theme.typeScale;
    final AppLocalizations l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    Md3eHomeLibraryManagementCopy.sectionTitle,
                    style: type.titleLarge.copyWith(color: scheme.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Md3eHomeLibraryManagementCopy.libraryCountSubtitle(
                      libraries.length,
                    ),
                    style: type.bodyMedium.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            _AddLibraryMenuButton(
              l10n: l10n,
              onAddLocalLibrary: onAddLocalLibrary,
              onAddRemoteLibrary: onAddRemoteLibrary,
            ),
          ],
        ),
        SizedBox(height: theme.spacing.lg),
        if (libraries.isEmpty)
          Text(
            l10n.sidebarAddLibraryTooltip,
            style: type.bodyMedium.copyWith(color: scheme.onSurfaceVariant),
          )
        else if (onLibrariesReorder != null)
          Md3eHomeLibraryReorderableList(
            libraries: libraries,
            onReorder: onLibrariesReorder!,
            onLibraryOpen: onLibraryOpen,
            onLibraryAction: onLibraryAction,
          )
        else
          Md3eSplitListGroup(
            children: libraries
                .map(
                  (Md3eHomeLibraryDashboardRow row) =>
                      Md3eHomeLibraryDashboardTile(
                    row: row,
                    onOpen: onLibraryOpen == null
                        ? null
                        : () => onLibraryOpen!(row.libraryId),
                    onAction: onLibraryAction == null
                        ? null
                        : (Md3eHomeLibraryManagementAction action) =>
                            onLibraryAction!(row.libraryId, action),
                  ),
                )
                .toList(growable: false),
          ),
      ],
    );
  }
}

class _AddLibraryMenuButton extends StatelessWidget {
  const _AddLibraryMenuButton({
    required this.l10n,
    this.onAddLocalLibrary,
    this.onAddRemoteLibrary,
  });

  final AppLocalizations l10n;
  final VoidCallback? onAddLocalLibrary;
  final VoidCallback? onAddRemoteLibrary;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final bool enabled =
        onAddLocalLibrary != null || onAddRemoteLibrary != null;

    return Md3eAnchoredMenu(
      enabled: enabled,
      position: M3EMenuAnchorPosition.bottomEnd,
      children: <M3EMenuEntry>[
        M3EMenuEntry(
          label: l10n.sidebarAddLocalLibrary,
          enabled: onAddLocalLibrary != null,
          onPressed: onAddLocalLibrary,
        ),
        M3EMenuEntry(
          label: l10n.sidebarAddRemoteLibrary,
          enabled: onAddRemoteLibrary != null,
          onPressed: onAddRemoteLibrary,
        ),
      ],
      anchorBuilder: (BuildContext context, VoidCallback open) {
        return M3EButton(
          style: M3EButtonStyle.tonal,
          label: Text(l10n.sidebarAddLibraryTooltip),
          onPressed: enabled ? open : null,
        );
      },
    );
  }
}

class Md3eHomeLibraryDashboardTile extends StatelessWidget {
  const Md3eHomeLibraryDashboardTile({
    super.key,
    required this.row,
    this.onOpen,
    this.onAction,
    this.showMoreMenu = true,
  });

  final Md3eHomeLibraryDashboardRow row;
  final VoidCallback? onOpen;
  final ValueChanged<Md3eHomeLibraryManagementAction>? onAction;
  final bool showMoreMenu;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final M3ETypeScale type = theme.typeScale;
    final IconData leadingIcon = switch (row.kind) {
      Md3eHomeLibraryKind.local => Symbols.folder,
      Md3eHomeLibraryKind.remote => Symbols.cloud,
    };

    final String statsLine =
        '${l10n.comicCount(row.comicCount)} · ${l10n.librarySeriesCount(row.seriesCount)}';

    final String? statusLine = _statusLine(context, row);
    final String? syncLine = _syncLine(context, row.lastSyncedAt);

    return Md3eSettingsTileShell(
      onTap: onOpen,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              leadingIcon,
              size: 24,
              color: _leadingColor(scheme, row.hint),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  row.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: type.titleMedium.copyWith(color: scheme.onSurface),
                ),
                const SizedBox(height: 4),
                Text(
                  statsLine,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: type.bodySmall.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (syncLine != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    syncLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: type.bodySmall.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (statusLine != null) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    statusLine,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: type.labelSmall.copyWith(
                      color: _hintColor(scheme, row.hint),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 4),
          if (showMoreMenu)
            Md3eHomeLibraryRowMoreMenu(
              l10n: l10n,
              row: row,
              onAction: onAction,
            ),
        ],
      ),
    );
  }

  Color _leadingColor(M3EColorScheme scheme, Md3eHomeLibraryRowHint hint) {
    return switch (hint) {
      Md3eHomeLibraryRowHint.unreachable => scheme.error,
      Md3eHomeLibraryRowHint.syncWarning => scheme.tertiary,
      Md3eHomeLibraryRowHint.none => scheme.onSurfaceVariant,
    };
  }

  Color _hintColor(M3EColorScheme scheme, Md3eHomeLibraryRowHint hint) {
    return switch (hint) {
      Md3eHomeLibraryRowHint.unreachable => scheme.error,
      Md3eHomeLibraryRowHint.syncWarning => scheme.tertiary,
      Md3eHomeLibraryRowHint.none => scheme.onSurfaceVariant,
    };
  }

  String? _syncLine(BuildContext context, DateTime? at) {
    if (at == null) {
      return null;
    }
    final String locale = Localizations.localeOf(context).toString();
    final String formatted = DateFormat.yMd(locale).add_Hm().format(at);
    return '${Md3eHomeLibraryManagementCopy.lastSyncLabel} · $formatted';
  }

  String? _statusLine(
    BuildContext context,
    Md3eHomeLibraryDashboardRow row,
  ) {
    if (row.scanInProgress) {
      return Md3eHomeLibraryManagementCopy.scanInProgressHint;
    }
    if (row.metadataRefreshInProgress) {
      return Md3eHomeLibraryManagementCopy.metadataRefreshInProgressHint;
    }
    return switch (row.hint) {
      Md3eHomeLibraryRowHint.syncWarning =>
        Md3eHomeLibraryManagementCopy.syncWarningHint(9),
      Md3eHomeLibraryRowHint.unreachable =>
        Md3eHomeLibraryManagementCopy.unreachableHint,
      Md3eHomeLibraryRowHint.none => null,
    };
  }
}

class Md3eHomeLibraryRowMoreMenu extends StatelessWidget {
  const Md3eHomeLibraryRowMoreMenu({
    super.key,
    required this.l10n,
    required this.row,
    this.onAction,
  });

  final AppLocalizations l10n;
  final Md3eHomeLibraryDashboardRow row;
  final ValueChanged<Md3eHomeLibraryManagementAction>? onAction;

  @override
  Widget build(BuildContext context) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final bool menuEnabled = onAction != null;
    final bool scanEnabled = menuEnabled && !row.busy;

    void emit(Md3eHomeLibraryManagementAction action) {
      onAction?.call(action);
    }

    final List<M3EMenuEntry> entries = <M3EMenuEntry>[
      M3EMenuEntry(
        label: l10n.sidebarScanLibrary,
        enabled: scanEnabled,
        onPressed: scanEnabled
            ? () => emit(Md3eHomeLibraryManagementAction.scan)
            : null,
      ),
      M3EMenuEntry(
        label: l10n.sidebarDeepScanLibrary,
        enabled: scanEnabled,
        onPressed: scanEnabled
            ? () => emit(Md3eHomeLibraryManagementAction.deepScan)
            : null,
      ),
      M3EMenuEntry(
        label: l10n.refreshMetadata,
        enabled: menuEnabled && !row.metadataRefreshInProgress,
        onPressed: menuEnabled && !row.metadataRefreshInProgress
            ? () => emit(Md3eHomeLibraryManagementAction.refreshMetadata)
            : null,
      ),
      M3EMenuEntry(
        label: row.kind == Md3eHomeLibraryKind.remote
            ? l10n.sidebarEditLibraryConnection
            : l10n.sidebarEditLibrary,
        enabled: menuEnabled,
        onPressed: menuEnabled
            ? () => emit(Md3eHomeLibraryManagementAction.edit)
            : null,
      ),
      M3EMenuEntry(
        label: l10n.sidebarDeleteLibrary,
        enabled: menuEnabled,
        onPressed:
            menuEnabled ? () => emit(Md3eHomeLibraryManagementAction.delete) : null,
      ),
    ];

    return Md3eAnchoredMenu(
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
