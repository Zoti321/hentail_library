/// 按 Flutter [ReorderCallback] 约定重排列表（纯函数，不做持久化）。
///
/// `newIndex` 与 [ReorderableListView] 一致：`oldIndex < newIndex` 时先减一再移动。
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
