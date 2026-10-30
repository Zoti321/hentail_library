/// [M3EListReorderHost] 的 `to` 为落位索引；[ReorderCallback] 的 `newIndex` 需按 Flutter 规则换算。
///
/// 换算后的 `newIndex` 与 [ReorderableListView] 一致：调用方对 `oldIndex < newIndex` 的情况
/// 先减一再移动（见 [applyMd3eReorder]）。
int md3eReorderTargetToFlutterNewIndex(int from, int to) =>
    from < to ? to + 1 : to;

/// 按 Flutter [ReorderCallback] 约定重排列表（纯函数，不做持久化）。
List<T> applyMd3eReorder<T>(List<T> items, int oldIndex, int newIndex) {
  if (items.isEmpty ||
      oldIndex < 0 ||
      oldIndex >= items.length ||
      newIndex < 0 ||
      newIndex > items.length) {
    return List<T>.of(items);
  }
  final List<T> next = List<T>.of(items);
  int target = newIndex;
  if (oldIndex < target) {
    target -= 1;
  }
  final T moved = next.removeAt(oldIndex);
  next.insert(target, moved);
  return next;
}
