/// 字符串列表的不可变增删（保持顺序、去重、不修改入参）。
library;

/// 追加 [value]；已存在时原样返回（同一实例）。
List<String> listWithAdded(List<String> list, String value) {
  if (list.contains(value)) {
    return list;
  }
  return <String>[...list, value];
}

/// 移除全部等于 [value] 的元素；无命中时原样返回（同一实例）。
List<String> listWithRemoved(List<String> list, String value) {
  if (!list.contains(value)) {
    return list;
  }
  return list.where((String e) => e != value).toList(growable: false);
}
