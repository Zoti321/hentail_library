import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/patterns/history/md3e_history_time_grouping.dart';

/// 分桶标题（今天 / 昨天 / …）。
String md3eHistoryTimeSectionLabel(
  AppLocalizations l10n,
  Md3eHistoryTimeSection section,
) {
  return switch (section) {
    Md3eHistoryTimeSection.today => l10n.historySectionToday,
    Md3eHistoryTimeSection.yesterday => l10n.historySectionYesterday,
    Md3eHistoryTimeSection.thisWeek => l10n.historySectionThisWeek,
    Md3eHistoryTimeSection.earlier => l10n.historySectionEarlier,
  };
}
