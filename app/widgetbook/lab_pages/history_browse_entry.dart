/// Lab 阅读历史行最小数据（分桶仅需 [lastReadTime]；行 UI 由 [itemBuilder] 提供）。
class Md3eHistoryBrowseEntry {
  const Md3eHistoryBrowseEntry({
    required this.lastReadTime,
  });

  final DateTime lastReadTime;
}
