/// [M3EListReorderHost] 的 `to` 为落位索引；[ReorderCallback] 的 `newIndex` 需按 Flutter 规则换算。
int md3eHomeLibraryReorderTargetToFlutterNewIndex(int from, int to) =>
    from < to ? to + 1 : to;

/// 首页库列表顺序变换（纯函数；UI 只负责触发索引，持久化由上层处理）。
List<T> applyMd3eHomeLibraryListReorder<T>(
  List<T> items,
  int oldIndex,
  int newIndex,
) {
  if (items.isEmpty ||
      oldIndex < 0 ||
      oldIndex >= items.length ||
      newIndex < 0 ||
      newIndex > items.length) {
    return List<T>.of(items);
  }
  if (oldIndex < newIndex) {
    newIndex -= 1;
  }
  final List<T> next = List<T>.of(items);
  final T moved = next.removeAt(oldIndex);
  next.insert(newIndex, moved);
  return next;
}
