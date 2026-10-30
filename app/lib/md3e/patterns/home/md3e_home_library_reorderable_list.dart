import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_library_dashboard_models.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_library_list_order.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_library_management_section.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_library_row_presentation.dart';
import 'package:hentai_library/md3e/widgets/settings/md3e_split_list_group.dart';
import 'package:hentai_library/md3e/widgets/settings/md3e_tonal_surface.dart';
import 'package:material_3_expressive/components/lists/components/m3e_list_reorder_exclude.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

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

        return M3EListItem(
          headline: row.displayName,
          supportingText: md3eHomeLibrarySupportingText(context, l10n, row),
          leading: Icon(
            md3eHomeLibraryKindIcon(row.kind),
            size: 24,
            color: md3eHomeLibraryHintColor(scheme, row.hint),
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
