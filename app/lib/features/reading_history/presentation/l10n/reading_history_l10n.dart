import 'package:hentai_library/design-system/l10n/app_localizations.dart';

extension ReadingHistoryL10nX on AppLocalizations {
  String relativeTimeAgo(DateTime time) {
    final DateTime now = DateTime.now();

    final Duration diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return relativeTimeJustNow;
    }

    if (diff.inMinutes < 60) {
      return relativeTimeMinutesAgo(diff.inMinutes);
    }

    if (diff.inHours < 24) {
      return relativeTimeHoursAgo(diff.inHours);
    }

    if (diff.inDays < 7) {
      return relativeTimeDaysAgo(diff.inDays);
    }

    final DateTime local = time.toLocal();

    return '${local.month}/${local.day}';
  }
}
