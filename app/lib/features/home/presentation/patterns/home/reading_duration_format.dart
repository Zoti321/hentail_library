import 'package:hentai_library/core/l10n/app_localizations.dart';

/// Home / 摘要卡用的 Reading duration 展示文案。
String formatReadingDurationForDisplay(
  Duration duration,
  AppLocalizations l10n,
) {
  final int totalMinutes = duration.inMinutes;
  if (totalMinutes < 1) {
    return l10n.homeReadingDurationZero;
  }
  final int hours = duration.inHours;
  final int minutes = totalMinutes.remainder(60);
  if (hours <= 0) {
    return l10n.homeReadingDurationMinutes(minutes);
  }
  if (minutes == 0) {
    return l10n.homeReadingDurationHours(hours);
  }
  return l10n.homeReadingDurationHoursMinutes(hours, minutes);
}
