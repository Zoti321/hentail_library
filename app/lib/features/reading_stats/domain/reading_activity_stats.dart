/// Reading activity stats 读模型：Finished comic 可见数量 + 累计 Reading duration。
class ReadingActivityStats {
  const ReadingActivityStats({
    required this.finishedCount,
    required this.totalDuration,
  });

  static const ReadingActivityStats empty = ReadingActivityStats(
    finishedCount: 0,
    totalDuration: Duration.zero,
  );

  final int finishedCount;
  final Duration totalDuration;
}
