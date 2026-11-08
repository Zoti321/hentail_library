import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/ui/patterns/home/home_library_dashboard_models.dart';

import 'home_library_row_presentation.dart';

import 'package:hentai_library/shared/ui/widgets/lists/reorder_exclude.dart';
import 'package:hentai_library/shared/ui/widgets/menu/anchored_menu.dart';
import 'package:hentai_library/shared/ui/widgets/settings/reorderable_split_list_group.dart';
import 'package:hentai_library/shared/ui/widgets/settings/settings_tile.dart';
import 'package:hentai_library/shared/ui/widgets/settings/split_list_group.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 首页「我的漫画库」：汇总 + 可操作的库列表（数据由调用方注入）。
///
/// 列表样式与设置页一致（[SplitListGroup] 分段圆角）。
class HomeLibraryManagementSection extends StatelessWidget {
  const HomeLibraryManagementSection({
    super.key,
    required this.libraries,
    this.onLibraryOpen,
    this.onLibraryAction,
    this.onAddLocalLibrary,
    this.onAddRemoteLibrary,
    this.onLibrariesReorder,
  });

  final List<HomeLibraryDashboardRow> libraries;
  final ValueChanged<String>? onLibraryOpen;
  final void Function(String libraryId, HomeLibraryManagementAction action)?
  onLibraryAction;
  final VoidCallback? onAddLocalLibrary;
  final VoidCallback? onAddRemoteLibrary;

  /// 传入时启用长按拖拽排序（[ReorderableSplitListGroup]，Flutter [ReorderCallback] 约定）；
  /// 为 null 时使用静态分段列表。
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
                    l10n.homeLibraryManagementSectionTitle,
                    style: type.titleLarge.copyWith(color: scheme.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.homeLibraryManagementCountSubtitle(libraries.length),
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
          ReorderableSplitListGroup(
            itemCount: libraries.length,
            itemKeyOf: (int index) => libraries[index].libraryId,
            onReorder: onLibrariesReorder!,
            itemBuilder: (BuildContext context, int index) =>
                _buildLibraryTile(libraries[index]),
          )
        else
          SplitListGroup(
            children: <Widget>[
              for (final HomeLibraryDashboardRow row in libraries)
                _buildLibraryTile(row),
            ],
          ),
      ],
    );
  }

  Widget _buildLibraryTile(HomeLibraryDashboardRow row) {
    return HomeLibraryDashboardTile(
      row: row,
      onOpen: onLibraryOpen == null
          ? null
          : () => onLibraryOpen!(row.libraryId),
      onAction: onLibraryAction == null
          ? null
          : (HomeLibraryManagementAction action) =>
                onLibraryAction!(row.libraryId, action),
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

    return AnchoredMenu(
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

/// 库列表的一行，与设置页 [SettingsTileShell] 同款（点按反馈与分段圆角由外层分段组提供）。
///
/// 行始终挂载可点按表面：即使没有 [onOpen]，按压 / 悬停 state layer 仍显示，只是点击不产生动作。
/// 点按层铺满整行（含「更多」所在区域），「更多」在其上层，点它只打开菜单，不打开整行。
class HomeLibraryDashboardTile extends StatelessWidget {
  const HomeLibraryDashboardTile({
    super.key,
    required this.row,
    this.onOpen,
    this.onAction,
    this.showMoreMenu = true,
  });

  final HomeLibraryDashboardRow row;
  final VoidCallback? onOpen;
  final ValueChanged<HomeLibraryManagementAction>? onAction;
  final bool showMoreMenu;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    // 点按层铺满整行并位于最底层：内容与「更多」在上层。
    // 点「更多」时命中按钮，不会冒泡到整行；其余区域命中点按层，state layer 覆盖整行。
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: SettingsTileShell(
            onTap: onOpen ?? _doNothing,
            child: const SizedBox.shrink(),
          ),
        ),
        Row(
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 0, 12),
                // 内容区点击穿透到底层点按层；只有「更多」参与命中。
                child: IgnorePointer(child: _HomeLibraryRowContent(row: row)),
              ),
            ),
            if (showMoreMenu)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                // 长按「更多」不触发列表拖拽。
                child: ReorderExclude(
                  child: HomeLibraryRowMoreMenu(
                    l10n: l10n,
                    row: row,
                    onAction: onAction,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

void _doNothing() {}

class _HomeLibraryRowContent extends StatelessWidget {
  const _HomeLibraryRowContent({required this.row});

  final HomeLibraryDashboardRow row;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final M3ETypeScale type = M3ETheme.of(context).typeScale;

    final String statsLine = homeLibraryStatsLine(l10n, row);
    final String? statusLine = homeLibraryStatusLine(l10n, row);
    final String? syncLine = homeLibrarySyncLine(context, row.lastSyncedAt);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            homeLibraryKindIcon(row.kind),
            size: 24,
            color: homeLibraryHintColor(scheme, row.hint),
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
                    color: homeLibraryHintColor(scheme, row.hint),
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
