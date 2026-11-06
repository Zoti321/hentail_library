import 'package:hentai_library/core/l10n/app_localizations.dart';

/// 阅读历史四档时间分桶（纯逻辑 + 分桶标题文案）。
enum HistoryTimeSection { today, yesterday, thisWeek, earlier }

/// 展示顺序（仅渲染非空分组）。
const List<HistoryTimeSection> kHistoryTimeSectionOrder = <HistoryTimeSection>[
  HistoryTimeSection.today,
  HistoryTimeSection.yesterday,
  HistoryTimeSection.thisWeek,
  HistoryTimeSection.earlier,
];

/// 同一分桶内的一条记录（泛型承载业务/预览模型）。
class HistoryTimeGroup<T> {
  const HistoryTimeGroup({required this.section, required this.items});

  final HistoryTimeSection section;
  final List<T> items;
}

DateTime _startOfLocalDay(DateTime value) {
  final DateTime local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

/// 将 [lastReadAt] 映射到四档分桶（相对 [clock]）。
HistoryTimeSection historyTimeSectionFor(DateTime lastReadAt, DateTime clock) {
  final DateTime today = _startOfLocalDay(clock);
  final DateTime readDay = _startOfLocalDay(lastReadAt);
  if (readDay == today) {
    return HistoryTimeSection.today;
  }
  final DateTime yesterday = today.subtract(const Duration(days: 1));
  if (readDay == yesterday) {
    return HistoryTimeSection.yesterday;
  }
  final int weekday = today.weekday;
  final DateTime weekStart = today.subtract(Duration(days: weekday - 1));
  if (!readDay.isBefore(weekStart) && readDay.isBefore(yesterday)) {
    return HistoryTimeSection.thisWeek;
  }
  return HistoryTimeSection.earlier;
}

/// 按四档分桶分组；空桶省略；桶内保持 [items] 原顺序。
List<HistoryTimeGroup<T>> groupHistoryByTimeSection<T>(
  List<T> items,
  DateTime Function(T item) lastReadAt, {
  DateTime? clock,
}) {
  if (items.isEmpty) {
    return <HistoryTimeGroup<T>>[];
  }
  final DateTime now = clock ?? DateTime.now();
  final Map<HistoryTimeSection, List<T>> buckets =
      <HistoryTimeSection, List<T>>{
        for (final HistoryTimeSection section in kHistoryTimeSectionOrder)
          section: <T>[],
      };
  for (final T item in items) {
    final HistoryTimeSection section = historyTimeSectionFor(
      lastReadAt(item),
      now,
    );
    buckets[section]!.add(item);
  }
  return <HistoryTimeGroup<T>>[
    for (final HistoryTimeSection section in kHistoryTimeSectionOrder)
      if (buckets[section]!.isNotEmpty)
        HistoryTimeGroup<T>(section: section, items: buckets[section]!),
  ];
}

/// 分桶标题（今天 / 昨天 / …）。
String historyTimeSectionLabel(
  AppLocalizations l10n,
  HistoryTimeSection section,
) {
  return switch (section) {
    HistoryTimeSection.today => l10n.historySectionToday,
    HistoryTimeSection.yesterday => l10n.historySectionYesterday,
    HistoryTimeSection.thisWeek => l10n.historySectionThisWeek,
    HistoryTimeSection.earlier => l10n.historySectionEarlier,
  };
}
