import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_library_dashboard_models.dart';
import 'package:hentai_library/md3e/motion/md3e_motion.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_library_management_copy.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_library_reorderable_list.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_library_row_presentation.dart';
import 'package:hentai_library/md3e/widgets/menu/md3e_anchored_menu.dart';
import 'package:hentai_library/md3e/widgets/settings/md3e_split_list_group.dart';
import 'package:hentai_library/md3e/widgets/settings/md3e_tonal_surface.dart';
import 'package:material_3_expressive/components/lists/components/m3e_card_radius_motion.dart';
import 'package:material_3_expressive/components/lists/components/m3e_list_reorder_exclude.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

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
          _buildStaticRows(),
      ],
    );
  }

  Widget _buildStaticRows() {
    final int last = libraries.length - 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int i = 0; i < libraries.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: kMd3eSplitListRowGap),
          Md3eHomeLibraryDashboardTile(
            row: libraries[i],
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(
                i == 0 ? kMd3eTonalSurfaceRadius : kMd3eSplitListInnerRadius,
              ),
              bottom: Radius.circular(
                i == last ? kMd3eTonalSurfaceRadius : kMd3eSplitListInnerRadius,
              ),
            ),
            onOpen: onLibraryOpen == null
                ? null
                : () => onLibraryOpen!(libraries[i].libraryId),
            onAction: onLibraryAction == null
                ? null
                : (Md3eHomeLibraryManagementAction action) =>
                      onLibraryAction!(libraries[i].libraryId, action),
          ),
        ],
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
    this.borderRadius = const BorderRadius.all(
      Radius.circular(kMd3eSplitListInnerRadius),
    ),
    this.embeddedInList = false,
  });

  final Md3eHomeLibraryDashboardRow row;
  final VoidCallback? onOpen;
  final ValueChanged<Md3eHomeLibraryManagementAction>? onAction;
  final bool showMoreMenu;
  final BorderRadius borderRadius;

  /// 为 true 时只输出行内容，表面、圆角、点击与拖拽交由外层 [M3EList] 的
  /// `M3ECardListItem` 提供；「更多」用 [M3EListReorderExclude] 包裹，长按它不会开始拖拽。
  final bool embeddedInList;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final M3ETypeScale type = theme.typeScale;

    final String statsLine = md3eHomeLibraryStatsLine(l10n, row);
    final String? statusLine = md3eHomeLibraryStatusLine(row);
    final String? syncLine = md3eHomeLibrarySyncLine(context, row.lastSyncedAt);

    if (embeddedInList) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: <Widget>[
            // 打开只绑定在内容区：M3EList 的行级 onTap 会在点击「更多」时也触发，
            // 所以行级 onTap 不负责打开（见 Md3eHomeLibraryReorderableList）。
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onOpen,
                child: _buildContent(
                  scheme: scheme,
                  type: type,
                  leadingIcon: md3eHomeLibraryKindIcon(row.kind),
                  statsLine: statsLine,
                  statusLine: statusLine,
                  syncLine: syncLine,
                ),
              ),
            ),
            if (showMoreMenu)
              M3EListReorderExclude(
                child: Md3eHomeLibraryRowMoreMenu(
                  l10n: l10n,
                  row: row,
                  onAction: onAction,
                ),
              ),
          ],
        ),
      );
    }

    // 「更多」按钮放在 Stack 的兄弟位置，而非卡片子树内：
    // M3ETappable 通过原始指针监听按压，子树内的按钮会让整行进入按压态。
    return Stack(
      children: <Widget>[
        _Md3eHomeLibraryRowSurface(
          onTap: onOpen,
          borderRadius: borderRadius,
          child: Padding(
            padding: EdgeInsets.only(right: showMoreMenu ? 44 : 0),
            child: _buildContent(
              scheme: scheme,
              type: type,
              leadingIcon: md3eHomeLibraryKindIcon(row.kind),
              statsLine: statsLine,
              statusLine: statusLine,
              syncLine: syncLine,
            ),
          ),
        ),
        if (showMoreMenu)
          Positioned(
            top: 0,
            bottom: 0,
            right: 12,
            child: Center(
              child: Md3eHomeLibraryRowMoreMenu(
                l10n: l10n,
                row: row,
                onAction: onAction,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildContent({
    required M3EColorScheme scheme,
    required M3ETypeScale type,
    required IconData leadingIcon,
    required String statsLine,
    required String? statusLine,
    required String? syncLine,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            leadingIcon,
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

/// 库列表行的 M3E 表面：与统计卡片一致的按压圆角动画（[M3ECardRadiusMotion]）与 state layer。
///
/// 仅按压时圆角变为 [kMd3eTonalSurfaceRadius]，hover 不改变圆角。
/// 无 [onTap] 时仍响应 hover / 按压，但不可聚焦、不显示点击光标、不触发 haptic。
class _Md3eHomeLibraryRowSurface extends StatefulWidget {
  const _Md3eHomeLibraryRowSurface({
    required this.child,
    required this.borderRadius,
    this.onTap,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;

  @override
  State<_Md3eHomeLibraryRowSurface> createState() =>
      _Md3eHomeLibraryRowSurfaceState();
}

class _Md3eHomeLibraryRowSurfaceState
    extends State<_Md3eHomeLibraryRowSurface> {
  bool _pressed = false;

  BorderRadius get _motionRadius => _pressed
      ? BorderRadius.circular(kMd3eTonalSurfaceRadius)
      : widget.borderRadius;

  @override
  Widget build(BuildContext context) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final bool interactive = widget.onTap != null;
    final bool reduceMotion = Md3eMotion.reduceMotionOf(context);

    return M3ECardRadiusMotion(
      radius: _motionRadius,
      snap: reduceMotion,
      builder: (BuildContext context, BorderRadius animatedRadius) {
        return M3ECard(
          variant: M3ECardVariant.filled,
          color: scheme.surfaceContainerLow,
          borderRadius: animatedRadius,
          elevation: M3EElevation.level0,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          onPressed: widget.onTap ?? () {},
          focusable: interactive,
          showFocusRing: false,
          haptic: M3EHapticFeedback.none,
          mouseCursor: interactive
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          onStateChanged: (M3EInteractionState state) {
            if (_pressed != state.pressed) {
              setState(() => _pressed = state.pressed);
            }
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 32),
            child: widget.child,
          ),
        );
      },
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
