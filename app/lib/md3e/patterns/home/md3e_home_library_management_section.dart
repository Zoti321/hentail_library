import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_library_dashboard_models.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_library_management_copy.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_library_row_presentation.dart';
import 'package:hentai_library/md3e/widgets/menu/md3e_anchored_menu.dart';
import 'package:hentai_library/md3e/widgets/settings/md3e_settings_tile.dart';
import 'package:hentai_library/md3e/widgets/settings/md3e_split_list_group.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 首页「我的漫画库」：汇总 + 可操作的库列表（Lab；数据由调用方注入）。
///
/// 列表样式与设置页一致（[Md3eSplitListGroup] 分段圆角）。
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

  /// 拖拽排序暂未接入，当前参数保留但不生效（待拖拽实现时再启用）。
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
        else
          Md3eSplitListGroup(
            children: <Widget>[
              for (final Md3eHomeLibraryDashboardRow row in libraries)
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
            ],
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

/// 库列表的一行，与设置页 [Md3eSettingsTileShell] 同款（点按反馈与分段圆角由外层分段组提供）。
///
/// 行始终挂载可点按表面：即使没有 [onOpen]，按压 / 悬停 state layer 仍显示，只是点击不产生动作。
/// 「更多」菜单位于点按区域右侧，不在 [Md3eSettingsTileShell] 内，因此点它不会打开整行。
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

    return Row(
      children: <Widget>[
        Expanded(
          child: Md3eSettingsTileShell(
            onTap: onOpen ?? _doNothing,
            child: _Md3eHomeLibraryRowContent(row: row),
          ),
        ),
        if (showMoreMenu)
          Md3eHomeLibraryRowMoreMenu(l10n: l10n, row: row, onAction: onAction),
      ],
    );
  }
}

void _doNothing() {}

class _Md3eHomeLibraryRowContent extends StatelessWidget {
  const _Md3eHomeLibraryRowContent({required this.row});

  final Md3eHomeLibraryDashboardRow row;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final M3ETypeScale type = M3ETheme.of(context).typeScale;

    final String statsLine = md3eHomeLibraryStatsLine(l10n, row);
    final String? statusLine = md3eHomeLibraryStatusLine(row);
    final String? syncLine = md3eHomeLibrarySyncLine(context, row.lastSyncedAt);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            md3eHomeLibraryKindIcon(row.kind),
            size: 24,
            color: md3eHomeLibraryHintColor(scheme, row.hint),
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
                style: type.bodySmall.copyWith(color: scheme.onSurfaceVariant),
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
                    color: md3eHomeLibraryHintColor(scheme, row.hint),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
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
        onPressed: menuEnabled
            ? () => emit(Md3eHomeLibraryManagementAction.delete)
            : null,
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
