import 'package:flutter/widgets.dart';

import 'package:hentai_library/core/l10n/app_localizations.dart';

import 'package:hentai_library/domain/library/library_age_restriction_filter.dart';

import 'package:hentai_library/domain/library/library_comic_sort_option.dart';

import 'package:hentai_library/domain/library/library_media_type_filter.dart';

import 'package:hentai_library/domain/library/library_series_sort_option.dart';

import 'package:hentai_library/domain/library/sync_library_types.dart';

import 'package:hentai_library/domain/models/app_setting.dart';

import 'package:hentai_library/domain/models/enums.dart';

import 'package:hentai_library/domain/reading/reading_mode.dart';

import 'package:intl/intl.dart';



extension AppLocalizationsContextX on BuildContext {

  AppLocalizations get l10n => AppLocalizations.of(this);

}



extension AppLocalizationsLabelsX on AppLocalizations {

  String themePreferenceLabel(AppThemePreference preference) {

    switch (preference) {

      case AppThemePreference.system:

        return themePreferenceSystem;

      case AppThemePreference.light:

        return themePreferenceLight;

      case AppThemePreference.dark:

        return themePreferenceDark;

    }

  }



  String localePreferenceLabel(AppLocalePreference preference) {

    switch (preference) {

      case AppLocalePreference.system:

        return localePreferenceSystem;

      case AppLocalePreference.zhCn:

        return localePreferenceZhCn;

      case AppLocalePreference.en:

        return localePreferenceEn;

    }

  }



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

    if (path.startsWith('/reader')) {

      return pageTitleReader;

    }

    if (path.startsWith('/comic/')) {

      return pageTitleComicDetail;

    }

    if (path.startsWith('/series/')) {

      return pageTitleSeriesDetail;

    }

    switch (path) {

      case '/home':

        return navHome;

      case '/local':

        return libraryTitle;

      case '/paths':

        return pageTitlePaths;

      case '/searched':

        return pageTitleSearchResults;

      case '/metadata':

      case '/tags':

      case '/authors':

        return navMetadata;

      case '/series':

        return pageTitleNotFound;

      case '/history':

        return navHistory;

      case '/settings':

        return navSettings;

      default:

        return 'hentai library';

    }

  }



  String libraryComicSortFieldLabel(LibraryComicSortField field) {

    return switch (field) {

      LibraryComicSortField.title => libraryComicSortTitle,

      LibraryComicSortField.createdAt => libraryComicSortCreatedAt,

      LibraryComicSortField.lastUpdatedAt => libraryComicSortLastUpdatedAt,

      LibraryComicSortField.publishedAt => libraryComicSortPublishedAt,

      LibraryComicSortField.readAt => libraryComicSortReadAt,

      LibraryComicSortField.fileSize => libraryComicSortFileSize,

      LibraryComicSortField.pageCount => libraryComicSortPageCount,

    };

  }



  String librarySeriesSortFieldLabel(LibrarySeriesSortField field) {

    return switch (field) {

      LibrarySeriesSortField.name => librarySeriesSortName,

      LibrarySeriesSortField.comicCount => librarySeriesSortComicCount,

      LibrarySeriesSortField.random => librarySeriesSortRandom,

    };

  }



  String libraryAgeRestrictionFilterLabel(LibraryAgeRestrictionFilter filter) {

    return switch (filter) {

      LibraryAgeRestrictionFilter.unrestricted => filterAgeUnrestricted,

      LibraryAgeRestrictionFilter.allAges => filterAgeAllAges,

      LibraryAgeRestrictionFilter.r18Only => filterAgeR18Only,

    };

  }



  String libraryMediaTypeFilterLabel(LibraryMediaTypeFilterOption option) {

    return switch (option) {

      LibraryMediaTypeFilterOption.pdf => filterMediaTypePdf,

      LibraryMediaTypeFilterOption.epub => filterMediaTypeEpub,

      LibraryMediaTypeFilterOption.archive => filterMediaTypeArchive,

    };

  }



  String serializationStatusLabel(SerializationStatus status) {

    return switch (status) {

      SerializationStatus.unknown => serializationStatusUnknown,

      SerializationStatus.ongoing => serializationStatusOngoing,

      SerializationStatus.ended => serializationStatusEnded,

      SerializationStatus.hiatus => serializationStatusHiatus,

    };

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



  String libraryScanSuccessToast({

    required ScanMode mode,

    required SyncLibraryProgress? progress,

  }) {

    final bool isDeepScan = mode == ScanMode.full;

    if (progress == null) {

      return isDeepScan ? libraryDeepScanComplete : libraryScanComplete;

    }

    return switch (progress.route) {

      SyncLibraryRoute.noRootsNoop =>

        isDeepScan ? libraryDeepScanCompleteNoRoots : libraryScanCompleteNoRoots,

      SyncLibraryRoute.noRootsCleared => isDeepScan

          ? libraryDeepScanCompleteCleared(progress.removedCount ?? 0)

          : libraryScanCompleteCleared(progress.removedCount ?? 0),

      SyncLibraryRoute.withRoots => isDeepScan

          ? libraryDeepScanCompleteStats(

              progress.addedCount ?? 0,

              progress.removedCount ?? 0,

              progress.keptCount ?? 0,

            )

          : libraryScanCompleteStats(

              progress.addedCount ?? 0,

              progress.removedCount ?? 0,

              progress.keptCount ?? 0,

            ),

    };

  }



  String readerModeCategoryLabel(ReaderModeCategory category) {

    return switch (category) {

      ReaderModeCategory.paged => readingModeCategoryPaged,

      ReaderModeCategory.webtoon => readingModeCategoryWebtoon,

    };

  }



  String pagedLayoutLabel(PagedLayout layout) {

    return switch (layout) {

      PagedLayout.single => readingModePagedSingle,

      PagedLayout.dual => readingModePagedDual,

      PagedLayout.dualNoCover => readingModePagedDualNoCover,

    };

  }



  String webtoonZoomModeLabel(WebtoonZoomMode mode) {

    return switch (mode) {

      WebtoonZoomMode.fitWidth => readingModeWebtoonFitWidth,

      WebtoonZoomMode.originalSize => readingModeWebtoonOriginalSize,

    };

  }



  String readingModeLabel(ReadingMode mode) {

    return switch (mode) {

      ReadingMode.paged => readingModePaged,

      ReadingMode.webtoon => readingModeWebtoon,

      ReadingMode.dualPage => readingModeDualPage,

      ReadingMode.dualPageNoCover => readingModeDualPageNoCover,

    };

  }



  String readerWebtoonMarginLabel(int percent) {

    if (percent == 0) {

      return readerSettingsMarginNone;

    }

    return readerSettingsMarginPercent(percent);

  }



  String metadataAddEntityTooltip(int tabIndex) {

    return switch (tabIndex) {

      0 => metadataAddAuthor,

      1 => metadataAddTag,

      _ => metadataAdd,

    };

  }



  String metadataSearchHint(int tabIndex) {

    return switch (tabIndex) {

      0 => metadataSearchAuthorsHint,

      1 => metadataSearchTagsHint,

      _ => librarySearchHint,

    };

  }



  String contentRatingLabel(ContentRating rating) {

    return switch (rating) {

      ContentRating.unknown => contentRatingUnknown,

      ContentRating.safe => contentRatingSafe,

      ContentRating.r18 => contentRatingR18,

    };

  }



  String formatFluentDatePickerLabel(DateTime date, Locale locale) {

    if (locale.languageCode == 'zh') {

      return DateFormat('yyyy年MM月dd日', locale.toString()).format(

        date.toLocal(),

      );

    }

    return DateFormat.yMMMd(locale.toString()).format(date.toLocal());

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



  String scanDialogRunningPhaseLabel(SyncLibraryProgress progress) {

    switch (progress.route) {

      case SyncLibraryRoute.noRootsNoop:

        return scanSyncing;

      case SyncLibraryRoute.noRootsCleared:

        return progress.phase == SyncLibraryPhase.writingDb

            ? scanWritingDb

            : scanClearingLibrary;

      case SyncLibraryRoute.withRoots:

        return switch (progress.phase) {

          SyncLibraryPhase.clearingLibrary => scanClearingLibrary,

          SyncLibraryPhase.scanning => scanScanningFiles,

          SyncLibraryPhase.writingDb => scanWritingDb,

          SyncLibraryPhase.generatingThumbnails => scanGeneratingThumbnails,

          SyncLibraryPhase.done => scanComplete,

          SyncLibraryPhase.failed => scanFailed,

        };

    }

  }



  String scanDialogProgressCount({

    required int done,

    required int total,

    required int failed,

  }) {

    if (failed > 0) {

      return scanProgressWithFailed(done, total, failed);

    }

    return scanProgressSimple(done, total);

  }



  String scanDialogThumbnailFailedSuffix(int count) {

    if (count <= 0) {

      return '';

    }

    return scanThumbnailFailedSuffix(count);

  }



  String scanDialogDoneSummaryLabel(SyncLibraryProgress? progress) {

    if (progress == null) {

      return scanComplete;

    }

    switch (progress.route) {

      case SyncLibraryRoute.noRootsNoop:

        return scanDoneNoRoots;

      case SyncLibraryRoute.noRootsCleared:

        return scanDoneCleared;

      case SyncLibraryRoute.withRoots:

        final int? removed = progress.removedCount;

        final int? added = progress.addedCount;

        final int? kept = progress.keptCount;

        final int? thumbFailed = progress.thumbnailFailedCount;

        if (removed != null && added != null && kept != null) {

          return scanDoneStats(

            removed,

            added,

            kept,

            scanDialogThumbnailFailedSuffix(thumbFailed ?? 0),

          );

        }

        return scanComplete;

    }

  }

}


