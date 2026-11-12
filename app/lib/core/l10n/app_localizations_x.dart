import 'package:flutter/widgets.dart';

import 'package:hentai_library/core/constants/app_routes.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';

extension AppLocalizationsContextX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// 与 feature 无关的通用文案（领域枚举标签由各 owner 的 l10n extension 提供）。
extension AppLocalizationsLabelsX on AppLocalizations {
  String homeGreetingPhraseForHour(int hour) {
    if (hour < 5) {
      return homeGreetingLateNight;
    }

    if (hour < 9) {
      return homeGreetingEarlyMorning;
    }

    if (hour < 12) {
      return homeGreetingMorning;
    }

    if (hour < 14) {
      return homeGreetingNoon;
    }

    if (hour < 18) {
      return homeGreetingAfternoon;
    }

    if (hour < 23) {
      return homeGreetingEvening;
    }

    return homeGreetingLate;
  }

  String pageTitleForPath(String path) {
    if (AppRoutes.isReaderPath(path)) {
      return pageTitleReader;
    }

    if (path.startsWith('${AppRoutes.libraries}/')) {
      return libraryTitle;
    }

    if (AppRoutes.isComicDetailPath(path)) {
      return pageTitleComicDetail;
    }

    if (AppRoutes.isSeriesDetailPath(path)) {
      return pageTitleSeriesDetail;
    }

    switch (path) {
      case AppRoutes.home:
        return navHome;

      case AppRoutes.local:
        return libraryTitle;

      case '/searched':
        return pageTitleSearchResults;

      case AppRoutes.metadata:
      case '/tags':
      case '/authors':
        return navMetadata;

      case '/series':
        return pageTitleNotFound;

      case AppRoutes.history:
        return navHistory;

      case AppRoutes.trash:
        return navTrash;

      case AppRoutes.settings:
        return navSettings;

      default:
        return 'hentai library';
    }
  }

  String seriesVolumeCountLabel(int count) => seriesDetailVolumeCount(count);

  String? seriesVolumeProgressLabel({
    required int current,
    required int? total,
  }) {
    if (total == null || total <= 0) {
      return null;
    }

    return seriesDetailVolumeProgress(current, total);
  }

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
