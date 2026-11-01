/// 阅读历史四档时间分桶（纯逻辑，无 UI / l10n）。
enum Md3eHistoryTimeSection {
  today,
  yesterday,
  thisWeek,
  earlier,
}

/// 展示顺序（仅渲染非空分组）。
const List<Md3eHistoryTimeSection> kMd3eHistoryTimeSectionOrder =
    <Md3eHistoryTimeSection>[
      Md3eHistoryTimeSection.today,
      Md3eHistoryTimeSection.yesterday,
      Md3eHistoryTimeSection.thisWeek,
      Md3eHistoryTimeSection.earlier,
    ];

/// 同一分桶内的一条记录（泛型承载业务/预览模型）。
class Md3eHistoryTimeGroup<T> {
  const Md3eHistoryTimeGroup({
    required this.section,
    required this.items,
  });

  final Md3eHistoryTimeSection section;
  final List<T> items;
}

DateTime _startOfLocalDay(DateTime value) {
  final DateTime local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

/// 将 [lastReadAt] 映射到四档分桶（相对 [clock]）。
Md3eHistoryTimeSection md3eHistoryTimeSectionFor(
  DateTime lastReadAt,
  DateTime clock,
) {
  final DateTime today = _startOfLocalDay(clock);
  final DateTime readDay = _startOfLocalDay(lastReadAt);
  if (readDay == today) {
    return Md3eHistoryTimeSection.today;
  }
  final DateTime yesterday = today.subtract(const Duration(days: 1));
  if (readDay == yesterday) {
    return Md3eHistoryTimeSection.yesterday;
  }
  final int weekday = today.weekday;
  final DateTime weekStart = today.subtract(Duration(days: weekday - 1));
  if (!readDay.isBefore(weekStart) && readDay.isBefore(yesterday)) {
    return Md3eHistoryTimeSection.thisWeek;
  }
  return Md3eHistoryTimeSection.earlier;
}

/// 按四档分桶分组；空桶省略；桶内保持 [items] 原顺序。
List<Md3eHistoryTimeGroup<T>> groupHistoryByTimeSection<T>(
  List<T> items,
  DateTime Function(T item) lastReadAt, {
  DateTime? clock,
}) {
  if (items.isEmpty) {
    return <Md3eHistoryTimeGroup<T>>[];
  }
  final DateTime now = clock ?? DateTime.now();
  final Map<Md3eHistoryTimeSection, List<T>> buckets =
      <Md3eHistoryTimeSection, List<T>>{
        for (final Md3eHistoryTimeSection section in kMd3eHistoryTimeSectionOrder)
          section: <T>[],
      };
  for (final T item in items) {
    final Md3eHistoryTimeSection section = md3eHistoryTimeSectionFor(
      lastReadAt(item),
      now,
    );
    buckets[section]!.add(item);
  }
  return <Md3eHistoryTimeGroup<T>>[
    for (final Md3eHistoryTimeSection section in kMd3eHistoryTimeSectionOrder)
      if (buckets[section]!.isNotEmpty)
        Md3eHistoryTimeGroup<T>(section: section, items: buckets[section]!),
  ];
}
