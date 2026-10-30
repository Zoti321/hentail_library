import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_library_dashboard_models.dart';
import 'package:hentai_library/md3e/widgets/lists/md3e_reorder_index.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_library_management_section.dart';
import 'package:hentai_library/md3e/widgets/settings/md3e_split_list_group.dart';
import 'package:hentai_library/md3e/widgets/settings/md3e_tonal_surface.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 可拖拽排序的库列表：[M3EList] 提供长按拖拽、分段圆角与 state layer，
/// 每行内容复用 [Md3eHomeLibraryDashboardTile]（`embeddedInList: true`）。
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
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;

    return M3EList(
      reorder: true,
      reorderState: const M3EListReorderState(showDragHandle: false),
      outerRadius: kMd3eTonalSurfaceRadius,
      innerRadius: kMd3eSplitListInnerRadius,
      gap: kMd3eSplitListRowGap,
      color: scheme.surfaceContainerLow,
      itemCount: libraries.length,
      onReorder: (int from, int to) =>
          onReorder(from, md3eReorderTargetToFlutterNewIndex(from, to)),
      // 行级 onTap 只为挂载 hover/按压 state layer（M3EList 仅在 onTap 非空时挂载），
      // 故始终提供且为空操作；真正的打开由 Tile 内容区的 onOpen 负责，避免点「更多」时误开。
      onTap: (int _) {},
      mouseCursor: onLibraryOpen == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      itemBuilder: (BuildContext context, int index) {
        final Md3eHomeLibraryDashboardRow row = libraries[index];
        return Md3eHomeLibraryDashboardTile(
          row: row,
          embeddedInList: true,
          onOpen: onLibraryOpen == null
              ? null
              : () => onLibraryOpen!(row.libraryId),
          onAction: onLibraryAction == null
              ? null
              : (Md3eHomeLibraryManagementAction action) =>
                    onLibraryAction!(row.libraryId, action),
        );
      },
    );
  }
}
