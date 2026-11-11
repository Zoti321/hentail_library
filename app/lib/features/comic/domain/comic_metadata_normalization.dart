/// Comic 元数据字段的规范化与顺序比较（comic 模块内部辅助，不经 public 暴露）。
String? normalizeOptionalMetadataText(String? value) {
  if (value == null) {
    return null;
  }
  final String trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

List<String> normalizeOrderedFacetNames(Iterable<String> source) {
  final List<String> out = <String>[];
  for (final String raw in source) {
    final String trimmed = raw.trim();
    if (trimmed.isEmpty || out.contains(trimmed)) {
      continue;
    }
    out.add(trimmed);
  }
  return out;
}

bool sameOrderedFacetNames(Iterable<String> a, Iterable<String> b) {
  final List<String> left = a.toList();
  final List<String> right = b.toList();
  if (left.length != right.length) {
    return false;
  }
  for (int i = 0; i < left.length; i++) {
    if (left[i] != right[i]) {
      return false;
    }
  }
  return true;
}
