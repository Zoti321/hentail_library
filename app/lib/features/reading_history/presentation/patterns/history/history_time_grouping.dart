import 'package:hentai_library/features/reading_history/domain/reading_history_section_counts.dart';
import 'package:hentai_library/l10n/app_localizations.dart';

/// 阅读历史五档时间分桶（对齐最长保留 1 年；纯逻辑 + 分桶标题文案）。
///
/// 顺序：今天 → 昨天 → 本周 → 本月 → 更早（年内其余）。
enum HistoryTimeSection { today, yesterday, thisWeek, thisMonth, earlier }

/// 展示顺序（含空桶占位）。
const List<HistoryTimeSection> kHistoryTimeSectionOrder = <HistoryTimeSection>[
  HistoryTimeSection.today,
  HistoryTimeSection.yesterday,
  HistoryTimeSection.thisWeek,
  HistoryTimeSection.thisMonth,
  HistoryTimeSection.earlier,
];

/// 同一分桶内的一条记录（泛型承载业务/预览模型）。
class HistoryTimeGroup<T> {
  const HistoryTimeGroup({
    required this.section,
    required this.items,
    required this.totalCount,
  });

  final HistoryTimeSection section;
  final List<T> items;

  /// 服务端全量桶计数；无服务端数据时可用 [items.length]。
  final int totalCount;
}

DateTime _startOfLocalDay(DateTime value) {
  final DateTime local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

/// 将 [lastReadAt] 映射到五档分桶（相对 [clock]）。
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
  final DateTime monthStart = DateTime(today.year, today.month);
  if (!readDay.isBefore(monthStart) && readDay.isBefore(weekStart)) {
    return HistoryTimeSection.thisMonth;
  }
  return HistoryTimeSection.earlier;
}

int sectionCountFor(
  ReadingHistorySectionCounts counts,
  HistoryTimeSection section,
) {
  return switch (section) {
    HistoryTimeSection.today => counts.today,
    HistoryTimeSection.yesterday => counts.yesterday,
    HistoryTimeSection.thisWeek => counts.thisWeek,
    HistoryTimeSection.thisMonth => counts.thisMonth,
    HistoryTimeSection.earlier => counts.earlier,
  };
}

ReadingHistorySectionCounts decrementSectionCount(
  ReadingHistorySectionCounts counts,
  HistoryTimeSection section,
) {
  return switch (section) {
    HistoryTimeSection.today =>
      counts.copyWith(today: (counts.today - 1).clamp(0, counts.today)),
    HistoryTimeSection.yesterday => counts.copyWith(
      yesterday: (counts.yesterday - 1).clamp(0, counts.yesterday),
    ),
    HistoryTimeSection.thisWeek =>
      counts.copyWith(thisWeek: (counts.thisWeek - 1).clamp(0, counts.thisWeek)),
    HistoryTimeSection.thisMonth => counts.copyWith(
      thisMonth: (counts.thisMonth - 1).clamp(0, counts.thisMonth),
    ),
    HistoryTimeSection.earlier =>
      counts.copyWith(earlier: (counts.earlier - 1).clamp(0, counts.earlier)),
  };
}

/// 按五档分桶分组；**始终输出五档**（空桶 `items` 为空）；桶内保持 [items] 原顺序。
///
/// [sectionCounts] 提供标题用全量计数；缺省时用已加载 [items] 长度。
List<HistoryTimeGroup<T>> groupHistoryByTimeSection<T>(
  List<T> items,
  DateTime Function(T item) lastReadAt, {
  DateTime? clock,
  ReadingHistorySectionCounts? sectionCounts,
}) {
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
      HistoryTimeGroup<T>(
        section: section,
        items: buckets[section]!,
        totalCount: sectionCounts != null
            ? sectionCountFor(sectionCounts, section)
            : buckets[section]!.length,
      ),
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
    HistoryTimeSection.thisMonth => l10n.historySectionThisMonth,
    HistoryTimeSection.earlier => l10n.historySectionEarlier,
  };
}
