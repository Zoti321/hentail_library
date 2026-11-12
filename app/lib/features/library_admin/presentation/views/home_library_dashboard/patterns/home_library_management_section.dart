import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/ui/patterns/home/home_library_dashboard_models.dart';

import 'home_library_dashboard_tile.dart';

export 'home_library_dashboard_tile.dart';
export 'home_library_row_more_menu.dart';

import 'package:hentai_library/design-system/design_system.dart';
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

  VoidCallback? _openFor(String libraryId) {
    final ValueChanged<String>? onLibraryOpen = this.onLibraryOpen;
    return onLibraryOpen == null ? null : () => onLibraryOpen(libraryId);
  }

  ValueChanged<HomeLibraryManagementAction>? _actionFor(String libraryId) {
    final void Function(String, HomeLibraryManagementAction)? onLibraryAction =
        this.onLibraryAction;
    return onLibraryAction == null
        ? null
        : (HomeLibraryManagementAction action) =>
              onLibraryAction(libraryId, action);
  }

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
                HomeLibraryDashboardTile(
                  row: libraries[index],
                  onOpen: _openFor(libraries[index].libraryId),
                  onAction: _actionFor(libraries[index].libraryId),
                ),
          )
        else
          SplitListGroup(
            children: <Widget>[
              for (final HomeLibraryDashboardRow row in libraries)
                HomeLibraryDashboardTile(
                  row: row,
                  onOpen: _openFor(row.libraryId),
                  onAction: _actionFor(row.libraryId),
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
