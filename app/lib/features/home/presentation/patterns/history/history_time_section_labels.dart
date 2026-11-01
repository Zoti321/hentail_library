import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/features/home/presentation/patterns/history/history_time_grouping.dart';

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
