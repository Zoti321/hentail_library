import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/shared/ui/patterns/home/home_library_dashboard_models.dart';
import 'package:hentai_library/shared/ui/widgets/settings/settings_tile.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import 'home_library_row_more_menu.dart';
import 'home_library_row_presentation.dart';

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
                padding: const EdgeInsets.only(left: 16, top: 12, bottom: 12),
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
