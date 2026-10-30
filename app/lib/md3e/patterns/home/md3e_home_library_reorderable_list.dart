import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_library_dashboard_models.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_library_list_order.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_library_management_copy.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_library_management_section.dart';
import 'package:hentai_library/md3e/widgets/settings/md3e_split_list_group.dart';
import 'package:hentai_library/md3e/widgets/settings/md3e_tonal_surface.dart';
import 'package:intl/intl.dart';
import 'package:material_3_expressive/components/lists/components/m3e_list_reorder_exclude.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// 可拖拽排序的库列表（视觉对齐 [Md3eSplitListGroup]；嵌在父级 [ScrollView] 时用 shrinkWrap）。
///
/// 拖拽态与动效由 [M3EList] + [M3EListReorderState] 提供（长按整行；无 drag handle）。
/// 「更多」包在 [M3EListReorderExclude] 内，避免与长按排序冲突。
class Md3eHomeLibraryReorderableList extends StatelessWidget {
  const Md3eHomeLibraryReorderableList({
    super.key,
    required this.libraries,
    required this.onReorder,
    this.onLibraryOpen,
    this.onLibraryAction,
  });

  final List<Md3eHomeLibraryDashboardRow> libraries;
  final void Function(int oldIndex, int newIndex) onReorder;
  final ValueChanged<String>? onLibraryOpen;
  final void Function(String libraryId, Md3eHomeLibraryManagementAction action)?
  onLibraryAction;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;

    return M3EList(
      reorder: true,
      reorderState: const M3EListReorderState(showDragHandle: false),
      outerRadius: kMd3eTonalSurfaceRadius,
      innerRadius: kMd3eSplitListInnerRadius,
      gap: kMd3eSplitListRowGap,
      color: scheme.surfaceContainerLow,
      itemCount: libraries.length,
      onReorder: (int from, int to) => onReorder(
        from,
        md3eHomeLibraryReorderTargetToFlutterNewIndex(from, to),
      ),
      // 始终提供 onTap：M3EList 仅在 onTap 非空时才挂载行的 hover/按压 state layer。
      // 无 onLibraryOpen 时点击为空操作，光标保持普通箭头。
      onTap: (int index) => onLibraryOpen?.call(libraries[index].libraryId),
      mouseCursor: onLibraryOpen == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      itemBuilder: (BuildContext context, int index) {
        final Md3eHomeLibraryDashboardRow row = libraries[index];
        final IconData leadingIcon = switch (row.kind) {
          Md3eHomeLibraryKind.local => Symbols.folder,
          Md3eHomeLibraryKind.remote => Symbols.cloud,
        };

        return M3EListItem(
          headline: row.displayName,
          supportingText: _supportingText(context, l10n, row),
          leading: Icon(
            leadingIcon,
            size: 24,
            color: _leadingColor(scheme, row.hint),
          ),
          trailing: M3EListReorderExclude(
            child: Md3eHomeLibraryRowMoreMenu(
              l10n: l10n,
              row: row,
              onAction: onLibraryAction == null
                  ? null
                  : (Md3eHomeLibraryManagementAction action) =>
                        onLibraryAction!(row.libraryId, action),
            ),
          ),
        );
      },
    );
  }
}

Color _leadingColor(M3EColorScheme scheme, Md3eHomeLibraryRowHint hint) {
  return switch (hint) {
    Md3eHomeLibraryRowHint.unreachable => scheme.error,
    Md3eHomeLibraryRowHint.syncWarning => scheme.tertiary,
    Md3eHomeLibraryRowHint.none => scheme.onSurfaceVariant,
  };
}

String _supportingText(
  BuildContext context,
  AppLocalizations l10n,
  Md3eHomeLibraryDashboardRow row,
) {
  final String stats =
      '${l10n.comicCount(row.comicCount)} · ${l10n.librarySeriesCount(row.seriesCount)}';
  final String? sync = _syncLine(context, row.lastSyncedAt);
  final String? status = _statusLine(row);
  final List<String> lines = <String>[stats];
  if (sync != null) {
    lines.add(sync);
  }
  if (status != null) {
    lines.add(status);
  }
  return lines.join('\n');
}

String? _syncLine(BuildContext context, DateTime? at) {
  if (at == null) {
    return null;
  }
  final String locale = Localizations.localeOf(context).toString();
  final String formatted = DateFormat.yMd(locale).add_Hm().format(at);
  return '${Md3eHomeLibraryManagementCopy.lastSyncLabel} · $formatted';
}

String? _statusLine(Md3eHomeLibraryDashboardRow row) {
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
