import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_library_dashboard_models.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_library_management_section.dart';
import 'package:hentai_library/md3e/widgets/settings/md3e_split_list_group.dart';

/// 可拖拽排序的首页库列表：分段圆角与长按拖拽由 [Md3eReorderableSplitListGroup] 提供，
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
  final ReorderCallback onReorder;
  final ValueChanged<String>? onLibraryOpen;
  final void Function(String libraryId, Md3eHomeLibraryManagementAction action)?
  onLibraryAction;

  @override
  Widget build(BuildContext context) {
    return Md3eReorderableSplitListGroup(
      itemCount: libraries.length,
      onReorder: onReorder,
      onItemTap: onLibraryOpen == null
          ? null
          : (int index) => onLibraryOpen!(libraries[index].libraryId),
      mouseCursor: SystemMouseCursors.click,
      itemBuilder: (BuildContext context, int index) {
        final Md3eHomeLibraryDashboardRow row = libraries[index];
        return Md3eHomeLibraryDashboardTile(
          row: row,
          embeddedInList: true,
          onAction: onLibraryAction == null
              ? null
              : (Md3eHomeLibraryManagementAction action) =>
                    onLibraryAction!(row.libraryId, action),
        );
      },
    );
  }
}
