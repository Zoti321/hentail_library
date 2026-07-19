// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get libraryTitle => 'Library';

  @override
  String get libraryEmptyTitle => 'No comics yet';

  @override
  String get libraryEmptyHint => 'Add a path under Selected Paths and scan';

  @override
  String get librarySeriesEmptyTitle => 'No series yet';

  @override
  String get librarySeriesEmptyHint =>
      'Series are created from scan results. Add a path and scan to see them here.';

  @override
  String get libraryNoMatchTitle => 'No matches';

  @override
  String get libraryNoMatchFilterHintComics =>
      'No comics match the current filters';

  @override
  String get libraryNoMatchFilterHintSeries =>
      'No series match the current filters';

  @override
  String comicCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comics',
      one: '1 comic',
      zero: '0 comics',
    );
    return '$_temp0';
  }

  @override
  String get settingsLanguageLabel => 'Language';

  @override
  String get localePreferenceSystem => 'System';

  @override
  String get localePreferenceZhCn => 'Chinese';

  @override
  String get localePreferenceEn => 'English';

  @override
  String get settingsThemeLabel => 'App theme';

  @override
  String get themePreferenceSystem => 'System';

  @override
  String get themePreferenceLight => 'Light';

  @override
  String get themePreferenceDark => 'Dark';

  @override
  String get navHome => 'Home';

  @override
  String get navMetadata => 'Manage';

  @override
  String get navHistory => 'History';

  @override
  String get navSettings => 'Settings';

  @override
  String get pageTitleReader => 'Reading';

  @override
  String get pageTitleComicDetail => 'Comic details';

  @override
  String get pageTitleSeriesDetail => 'Series details';

  @override
  String get pageTitlePaths => 'Library paths';

  @override
  String get pageTitleSearchResults => 'Search results';

  @override
  String get pageTitleNotFound => 'Page not found';

  @override
  String get shellOpenNavMenu => 'Open navigation menu';

  @override
  String get shellLoadFailed => 'Failed to load';

  @override
  String get shellLoading => 'Loading…';

  @override
  String get shellBack => 'Back';

  @override
  String get shellBackToSettings => 'Back to settings';

  @override
  String get shellRetry => 'Retry';

  @override
  String get shellRetrying => 'Retrying…';

  @override
  String get shellProcessing => 'Processing…';

  @override
  String get homeTitle => 'Home';

  @override
  String get homeScanLibrary => 'Scan library';

  @override
  String get homeGreetingLateNight => 'Good evening';

  @override
  String get homeGreetingEarlyMorning => 'Good morning';

  @override
  String get homeGreetingMorning => 'Good morning';

  @override
  String get homeGreetingNoon => 'Good afternoon';

  @override
  String get homeGreetingAfternoon => 'Good afternoon';

  @override
  String get homeGreetingEvening => 'Good evening';

  @override
  String get homeGreetingLate => 'Good night';

  @override
  String homeGreetingReader(String greeting) {
    return '$greeting, reader';
  }

  @override
  String get homeEmptyTitle => 'No comics imported yet';

  @override
  String get homeEmptyHint =>
      'Add library folders in Settings and scan. If already configured, check Selected Paths or scan again.';

  @override
  String get pathsTitle => 'Selected paths';

  @override
  String get homeStatSeries => 'Series';

  @override
  String get homeStatTags => 'Tags';

  @override
  String get homeStatAuthors => 'Authors';

  @override
  String homeComicTotal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comics total',
      one: '1 comic total',
    );
    return '$_temp0';
  }

  @override
  String homeSeriesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count series',
      one: '1 series',
    );
    return '$_temp0';
  }

  @override
  String homeTagCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tags',
      one: '1 tag',
    );
    return '$_temp0';
  }

  @override
  String homeAuthorCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count authors',
      one: '1 author',
    );
    return '$_temp0';
  }

  @override
  String get homeNoAuthors => 'No authors yet';

  @override
  String get homeContinueReading => 'Continue reading';

  @override
  String get homeNoReadingHistory => 'No reading history yet, ';

  @override
  String get homeGoToLibrary => 'Go to library';

  @override
  String get historyTitle => 'Reading history';

  @override
  String get historyClearAction => 'Clear reading history';

  @override
  String get historyClearedToast => 'Reading history cleared';

  @override
  String historyRecordSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries · kept for 30 days max',
      one: '1 entry · kept for 30 days max',
    );
    return '$_temp0';
  }

  @override
  String get historySearchHint => 'Search history...';

  @override
  String get historyEmpty => 'No reading history yet';

  @override
  String get historyNoMatch => 'No matching entries';

  @override
  String get historyDeletedToast => 'Entry removed';

  @override
  String get pathsSavedHeading => 'Saved paths';

  @override
  String pathsTotalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count paths',
      one: '1 path',
    );
    return '$_temp0';
  }

  @override
  String get pathsEmptyHint => 'No paths yet. Add a folder.';

  @override
  String get pathsAddButton => 'Add path';

  @override
  String get pathsAddedOneToast => 'Path added';

  @override
  String get pathsRemovedToast => 'Path removed';

  @override
  String get pathsRemoveAction => 'Remove path';

  @override
  String get pathsLoadFailed => 'Failed to load paths';

  @override
  String get notFoundTitle => 'Page not found';

  @override
  String get notFoundHint =>
      'This link may be outdated or the page was removed.';

  @override
  String get notFoundGoHome => 'Back to home';

  @override
  String get notFoundGoLibrary => 'Go to library';

  @override
  String get settingsGroupPersonalization => 'Personalization';

  @override
  String get settingsGroupLibrary => 'Library';

  @override
  String get settingsGroupDiagnostics => 'Diagnostics & support';

  @override
  String get settingsGroupAbout => 'About';

  @override
  String get settingsDiagnosticModeLabel => 'Verbose diagnostics';

  @override
  String get settingsDiagnosticModeDescriptionEnabled =>
      'Enabled: Dart and Rust log more detail';

  @override
  String get settingsDiagnosticModeDescriptionDisabled =>
      'Temporarily increase log verbosity to help reproduce issues';

  @override
  String get settingsDiagnosticModeEnabledBadge => 'Enabled';

  @override
  String get settingsExportLogsLabel => 'Export logs';

  @override
  String get settingsExportLogsDescription =>
      'Bundle app and core logs for troubleshooting';

  @override
  String get settingsLibraryLocationLabel => 'Library paths';

  @override
  String get settingsAutoScanLabel => 'Auto scan';

  @override
  String get settingsAutoUpdateLabel => 'Automatic updates';

  @override
  String settingsCurrentVersion(String version) {
    return 'Current version v$version';
  }

  @override
  String get settingsCurrentVersionLoading => 'Current version …';

  @override
  String get settingsCheckForUpdatesLabel => 'Check for updates';

  @override
  String get settingsUpdateCheckFailed =>
      'Update check failed. Please try again later.';

  @override
  String get settingsUpdateUpToDate => 'You\'re on the latest version';

  @override
  String get libraryTabComics => 'Comics';

  @override
  String get libraryTabSeries => 'Series';

  @override
  String librarySeriesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count series',
      one: '1 series',
    );
    return '$_temp0';
  }

  @override
  String get libraryManageScanPaths => 'Manage scan paths';

  @override
  String get librarySearchHint => 'Search…';

  @override
  String get librarySearchKeywordEmpty => 'Keyword cannot be empty';

  @override
  String get libraryFilterSortTooltip => 'Filter & sort';

  @override
  String get libraryFilterSortSemantic => 'Open filter & sort';

  @override
  String get libraryPageSizeTooltip => 'Items per page';

  @override
  String get libraryPageSizeSemantic => 'Set items per page';

  @override
  String get libraryScanCancelledToast => 'Scan cancelled';

  @override
  String get libraryScanningDeep => 'Deep scanning…';

  @override
  String get libraryScanning => 'Scanning…';

  @override
  String get libraryCancelScan => 'Cancel scan';

  @override
  String get libraryMoreActions => 'More actions';

  @override
  String get libraryMoreActionsSemantic => 'Open more actions';

  @override
  String get libraryRefresh => 'Refresh';

  @override
  String get libraryScan => 'Scan';

  @override
  String get libraryDeepScan => 'Deep scan';

  @override
  String get libraryScrollToTop => 'Back to top';

  @override
  String get libraryFilterSection => 'Filter';

  @override
  String get librarySortSection => 'Sort';

  @override
  String get libraryAgeRestrictionFilter => 'Age restriction';

  @override
  String get libraryMediaTypeFilter => 'Media type';

  @override
  String get libraryComingSoon => 'Coming soon';

  @override
  String get libraryComicSortTitle => 'Title';

  @override
  String get libraryComicSortCreatedAt => 'Date added';

  @override
  String get libraryComicSortLastUpdatedAt => 'Last updated';

  @override
  String get libraryComicSortPublishedAt => 'Published date';

  @override
  String get libraryComicSortReadAt => 'Read date';

  @override
  String get libraryComicSortFileSize => 'File size';

  @override
  String get libraryComicSortPageCount => 'Page count';

  @override
  String get librarySeriesSortName => 'Name';

  @override
  String get librarySeriesSortComicCount => 'Comic count';

  @override
  String get librarySeriesSortRandom => 'Random';

  @override
  String get filterAgeUnrestricted => 'All';

  @override
  String get filterAgeAllAges => 'All ages';

  @override
  String get filterAgeR18Only => 'R18 only';

  @override
  String get filterMediaTypePdf => 'PDF';

  @override
  String get filterMediaTypeEpub => 'EPUB';

  @override
  String get filterMediaTypeArchive => 'Archive';

  @override
  String get libraryScanComplete => 'Scan complete';

  @override
  String get libraryDeepScanComplete => 'Deep scan complete';

  @override
  String get libraryScanCompleteNoRoots =>
      'Scan complete: no scan paths configured';

  @override
  String get libraryDeepScanCompleteNoRoots =>
      'Deep scan complete: no scan paths configured';

  @override
  String libraryScanCompleteCleared(int count) {
    return 'Scan complete: removed $count items';
  }

  @override
  String libraryDeepScanCompleteCleared(int count) {
    return 'Deep scan complete: removed $count items';
  }

  @override
  String libraryScanCompleteStats(int added, int removed, int kept) {
    return 'Scan complete: added $added, removed $removed, kept $kept';
  }

  @override
  String libraryDeepScanCompleteStats(int added, int removed, int kept) {
    return 'Deep scan complete: added $added, removed $removed, kept $kept';
  }

  @override
  String get searchResultsTitle => 'Search results';

  @override
  String searchResultsForQuery(String query) {
    return 'Search results for \"$query\"';
  }

  @override
  String get searchEnterKeyword => 'Enter a keyword and press Enter to search';

  @override
  String searchLoadFailed(String error) {
    return 'Failed to load: $error';
  }

  @override
  String get searchBackToLibrary => 'Back to library';

  @override
  String get searchScrollLeft => 'Scroll left';

  @override
  String get searchScrollRight => 'Scroll right';

  @override
  String comicDetailPageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages',
      one: '1 page',
    );
    return '$_temp0';
  }

  @override
  String get comicDetailAuthors => 'Authors';

  @override
  String get comicDetailTags => 'Tags';

  @override
  String get comicDetailResourceFormat => 'Format';

  @override
  String get comicDetailResourceSize => 'Size';

  @override
  String get comicDetailResourcePath => 'Path';

  @override
  String get comicDetailAddedAt => 'Added';

  @override
  String get comicDetailUpdatedAt => 'Updated';

  @override
  String get comicDetailRead => 'Read';

  @override
  String get comicDetailReadIncognito => 'Read incognito';

  @override
  String get comicDetailEditMetadata => 'Edit metadata';

  @override
  String get comicDetailShowInExplorer => 'Show in file explorer';

  @override
  String get comicDetailShowInExplorerFailed =>
      'Could not show this item in File Explorer';

  @override
  String get comicDetailDelete => 'Delete';

  @override
  String get comicDetailDeleteTitle => 'Delete comic?';

  @override
  String comicDetailDeleteConfirm(String title) {
    return '\"$title\" will be deleted. This cannot be undone.';
  }

  @override
  String get comicDetailCancel => 'Cancel';

  @override
  String get comicDetailDeletedToast => 'Comic deleted';

  @override
  String get comicDetailNotFound => 'Comic not found or removed';

  @override
  String get comicDetailLoadFailedRetry => 'Failed to load. Please retry.';

  @override
  String get comicDetailGoToLibrary => 'Go to library';

  @override
  String get comicDetailSeriesNavConflict =>
      'Series data error: this comic belongs to multiple series; series navigation is unavailable.';

  @override
  String get comicDetailSeriesPrev => 'Previous in series';

  @override
  String get comicDetailSeriesPrevSemantic => 'Previous in series';

  @override
  String get comicDetailSeriesCatalog => 'Series catalog';

  @override
  String get comicDetailSeriesNext => 'Next in series';

  @override
  String get comicDetailSeriesNextSemantic => 'Next in series';

  @override
  String get seriesDetailEdit => 'Edit series';

  @override
  String get seriesDetailNoComics => 'No comics in this series';

  @override
  String get seriesDetailComicsLoadFailed => 'Failed to load comic list';

  @override
  String get seriesDetailUnknown => 'Unknown series';

  @override
  String seriesDetailNotFound(String name) {
    return 'Series not found: \"$name\"';
  }

  @override
  String seriesDetailVolumeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count volumes',
      one: '1 volume',
    );
    return '$_temp0';
  }

  @override
  String seriesDetailVolumeProgress(int current, int total) {
    return '$current / $total volumes';
  }

  @override
  String seriesDetailPaginationPage(int page, int totalPages) {
    return 'Page $page of $totalPages';
  }

  @override
  String get seriesDetailPaginationFirst => 'First page';

  @override
  String get seriesDetailPaginationPrevious => 'Previous page';

  @override
  String get seriesDetailPaginationNext => 'Next page';

  @override
  String get seriesDetailPaginationLast => 'Last page';

  @override
  String get serializationStatusOngoing => 'Ongoing';

  @override
  String get serializationStatusEnded => 'Completed';

  @override
  String get serializationStatusHiatus => 'Hiatus';

  @override
  String get serializationStatusUnknown => 'Unknown';

  @override
  String get readerSettingsTitle => 'Reading settings';

  @override
  String get readerSettingsClose => 'Close';

  @override
  String get readerSettingsGeneral => 'General';

  @override
  String get readerSettingsReadingMode => 'Reading mode';

  @override
  String get readerSettingsAutoPlay => 'Auto-play';

  @override
  String get readerSettingsPlayInterval => 'Play interval';

  @override
  String get readerSettingsSecondsSuffix => 'sec';

  @override
  String get readerSettingsWebtoonMode => 'Webtoon mode';

  @override
  String get readerSettingsPagedOptions => 'Paged reader options';

  @override
  String get readerSettingsHorizontalMargin => 'Horizontal margin';

  @override
  String get readerSettingsMarginNone => 'None (0%)';

  @override
  String readerSettingsMarginPercent(int percent) {
    return '$percent%';
  }

  @override
  String get readerSettingsZoomMode => 'Zoom mode';

  @override
  String get readerSettingsPageLayout => 'Page layout';

  @override
  String get readingModeCategoryPaged => 'Paged';

  @override
  String get readingModeCategoryWebtoon => 'Webtoon';

  @override
  String get readingModePaged => 'Paged';

  @override
  String get readingModeWebtoon => 'Webtoon';

  @override
  String get readingModeDualPage => 'Dual page';

  @override
  String get readingModeDualPageNoCover => 'Dual page (cover separate)';

  @override
  String get readingModePagedSingle => 'Single page';

  @override
  String get readingModePagedDual => 'Dual page';

  @override
  String get readingModePagedDualNoCover => 'Dual page (cover separate)';

  @override
  String get readingModeWebtoonFitWidth => 'Fit width';

  @override
  String get readingModeWebtoonOriginalSize => 'Original size';

  @override
  String get readerSetComicCover => 'Set current page as comic cover';

  @override
  String get readerSetSeriesCover => 'Set current page as series cover';

  @override
  String get readerMore => 'More';

  @override
  String get readerMoreSemantic => 'More reading options';

  @override
  String get readerStateNotReady => 'Reader not ready';

  @override
  String get readerComicCoverSet => 'Set as comic cover';

  @override
  String readerComicCoverSetFailed(String error) {
    return 'Failed to set comic cover: $error';
  }

  @override
  String get readerSeriesCoverSet => 'Set as series cover';

  @override
  String readerSeriesCoverSetFailed(String error) {
    return 'Failed to set series cover: $error';
  }

  @override
  String get readerBackSemantic => 'Go back';

  @override
  String get readerExitFullscreen => 'Exit fullscreen';

  @override
  String get readerEnterFullscreen => 'Fullscreen';

  @override
  String get readerExitFullscreenSemantic => 'Exit fullscreen';

  @override
  String get readerEnterFullscreenSemantic => 'Enter fullscreen';

  @override
  String get readerOpenSettingsSemantic => 'Open reading settings';

  @override
  String get readerSeriesCatalog => 'Series catalog';

  @override
  String get readerPrevVolume => 'Previous volume';

  @override
  String get readerPrevVolumeSemantic => 'Previous volume in series';

  @override
  String get readerFirstPage => 'First page';

  @override
  String get readerFirstPageSemantic => 'Go to first page';

  @override
  String get readerNextVolume => 'Next volume';

  @override
  String get readerNextVolumeSemantic => 'Next volume in series';

  @override
  String get readerLastPage => 'Last page';

  @override
  String get readerLastPageSemantic => 'Go to last page';

  @override
  String get readerPrevPage => 'Previous page';

  @override
  String get readerNextPage => 'Next page';

  @override
  String get readerDisableAutoPlay => 'Disable auto-play';

  @override
  String get readerEnableAutoPlay => 'Enable auto-play';

  @override
  String get readerInvalidParams => 'Invalid reader params: missing comic_id';

  @override
  String get readerSeriesAdvancePrompt =>
      'Turn the page again to go to the next volume';

  @override
  String get readerNoImages => 'No images';

  @override
  String get metadataTabAuthors => 'Authors';

  @override
  String get metadataTabTags => 'Tags';

  @override
  String get metadataAddAuthor => 'Add author';

  @override
  String get metadataAddTag => 'Add tag';

  @override
  String get metadataAdd => 'Add';

  @override
  String get metadataSearchAuthorsHint => 'Search authors…';

  @override
  String get metadataSearchTagsHint => 'Search tags…';

  @override
  String get metadataRename => 'Rename';

  @override
  String get metadataDelete => 'Delete';

  @override
  String get metadataMoreActions => 'More actions';

  @override
  String get metadataAllAuthors => 'All authors';

  @override
  String get metadataAllTags => 'All tags';

  @override
  String metadataTotalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String metadataSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selected',
      one: '1 selected',
    );
    return '$_temp0';
  }

  @override
  String get metadataSelect => 'Select';

  @override
  String get metadataDeselect => 'Deselect';

  @override
  String get metadataRenameAuthor => 'Rename author';

  @override
  String get metadataRenameTag => 'Rename tag';

  @override
  String get metadataNewName => 'New name';

  @override
  String get metadataRenameAuthorHint => 'Enter a new author name…';

  @override
  String get metadataRenameTagHint => 'Enter a new tag name…';

  @override
  String get metadataNameLabel => 'Name';

  @override
  String get metadataAddAuthorHint => 'Enter author name…';

  @override
  String get metadataAddTagHint => 'Enter tag name…';

  @override
  String get metadataAuthorDeletedToast => 'Author deleted';

  @override
  String get metadataTagDeletedToast => 'Tag deleted';

  @override
  String get metadataAuthorsEmptyTitle => 'No authors yet';

  @override
  String get metadataAuthorsEmptyHint => 'Add, rename, or delete authors here.';

  @override
  String get metadataTagsEmptyTitle => 'No tags yet';

  @override
  String get metadataTagsEmptyHint => 'Add, rename, or delete tags here.';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonSaveChanges => 'Save changes';

  @override
  String get commonClose => 'Close';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonRemove => 'Remove';

  @override
  String get commonClear => 'Clear';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonOk => 'OK';

  @override
  String get commonLoadFailed => 'Failed to load';

  @override
  String get commonBack => 'Back';

  @override
  String get commonSavedToast => 'Saved';

  @override
  String get dialogEditSeriesTitle => 'Edit series';

  @override
  String get dialogEditSeriesSavedToast => 'Series info saved';

  @override
  String get dialogEditMetadataTitle => 'Edit metadata';

  @override
  String get dialogEditMetadataTabGeneral => 'General';

  @override
  String get dialogEditMetadataTabAuthorsTags => 'Authors & tags';

  @override
  String get formSeriesNameLabel => 'Series name';

  @override
  String get formSeriesSerializationStatusLabel => 'Serialization status';

  @override
  String get formSeriesTotalCountLabel => 'Total volumes';

  @override
  String get formSeriesTotalCountHint => 'Leave blank to unset';

  @override
  String get formComicTitleLabel => 'Title';

  @override
  String get formComicTitleHint => 'Edit comic title';

  @override
  String get formComicDescriptionLabel => 'Description';

  @override
  String get formComicDescriptionHint => 'Add a description…';

  @override
  String get formPublishedDateLabel => 'Published date';

  @override
  String get formAgeRestrictionLabel => 'Age restriction';

  @override
  String get formDatePickerHint => 'Select published date';

  @override
  String get formDatePickerHelp => 'Select published date';

  @override
  String get formDateFieldLabel => 'Date';

  @override
  String get formDateFieldHint => 'Year / month / day';

  @override
  String get formDateInvalidFormat => 'Invalid date format';

  @override
  String get formDateOutOfRange => 'Date out of range';

  @override
  String get formDateClearTooltip => 'Clear date';

  @override
  String get formAuthorSelectPlaceholder => 'Select or enter author…';

  @override
  String get formAuthorListLoadFailed => 'Failed to load authors';

  @override
  String get formAuthorEmptyCatalog => 'No authors yet';

  @override
  String get formAuthorEmptyRemaining => 'No more options';

  @override
  String get formTagSelectPlaceholder => 'Select or enter tag…';

  @override
  String get formTagListLoadFailed => 'Failed to load tags';

  @override
  String get formTagEmptyCatalog => 'No tags yet';

  @override
  String get formTagEmptyRemaining => 'No more options';

  @override
  String get scanDialogTitle => 'Scan library';

  @override
  String get scanBackgroundAction => 'Scan in background';

  @override
  String get scanPreparing => 'Preparing…';

  @override
  String get scanGeneratingThumbnails => 'Generating thumbnails…';

  @override
  String scanProgressSimple(int done, int total) {
    return '$done / $total';
  }

  @override
  String scanProgressWithFailed(int done, int total, int failed) {
    return '$done / $total · $failed failed';
  }

  @override
  String get scanSyncing => 'Syncing…';

  @override
  String get scanWritingDb => 'Writing to database…';

  @override
  String get scanClearingLibrary => 'Clearing library…';

  @override
  String get scanScanningFiles => 'Scanning files…';

  @override
  String get scanComplete => 'Sync complete';

  @override
  String get scanFailed => 'Sync failed';

  @override
  String get scanCancelled => 'Scan cancelled';

  @override
  String scanBackgroundThumbnails(int done, int total, String failedSuffix) {
    return 'Generating thumbnails in background $done / $total$failedSuffix';
  }

  @override
  String scanThumbnailFailedSuffix(int count) {
    return ' · $count thumbnails failed';
  }

  @override
  String get scanDoneNoRoots =>
      'No valid paths configured; library is empty. Sync finished.';

  @override
  String get scanDoneCleared => 'Existing comic data cleared.';

  @override
  String scanDoneStats(int removed, int added, int kept, String thumbSuffix) {
    return 'Sync complete · removed $removed · added $added · kept $kept$thumbSuffix';
  }

  @override
  String updateNewVersionTitle(String version) {
    return 'New version v$version';
  }

  @override
  String updatePublishedOn(String date) {
    return 'Released $date';
  }

  @override
  String get updateRemindLater => 'Remind me later';

  @override
  String get updateViewDetails => 'View details';

  @override
  String get updateNow => 'Update now';

  @override
  String get updateManualDownloadToast =>
      'Download the installer for your system manually';

  @override
  String get updateDownloadingTitle => 'Downloading update';

  @override
  String get updateDownloadFailed => 'Download failed. Please retry.';

  @override
  String get confirmDeleteTagsTitle => 'Confirm deletion';

  @override
  String confirmDeleteTagsContent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Delete $count tags and remove them from all comics. This cannot be undone.',
      one: 'Delete 1 tag and remove it from all comics. This cannot be undone.',
    );
    return '$_temp0';
  }

  @override
  String get confirmRemovePathTitle => 'Confirm removal';

  @override
  String get confirmRemovePathContent =>
      'This path will be removed from the library. This cannot be undone.';

  @override
  String get confirmClearHistoryTitle => 'Confirm clear';

  @override
  String get confirmClearHistoryContent =>
      'All reading history will be cleared. This cannot be undone.';

  @override
  String get contextMenuGoToDetail => 'Go to details';

  @override
  String get breadcrumbReturnLibrary => 'Back to library';

  @override
  String breadcrumbReturnLibraryWithTrail(String trail) {
    return 'Back to library, current: $trail';
  }

  @override
  String get diagnosticModeBannerMessage =>
      'Diagnostic mode on · logging extra detail';

  @override
  String get diagnosticModeDisable => 'Turn off';

  @override
  String get sidebarCollapse => 'Collapse sidebar';

  @override
  String get sidebarExpand => 'Expand sidebar';

  @override
  String get filterAdvancedTitle => 'Advanced filters';

  @override
  String filterResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '1 result',
    );
    return '$_temp0';
  }

  @override
  String get sortAndViewTitle => 'Sort & view';

  @override
  String get contentRatingUnknown => 'Unknown';

  @override
  String get contentRatingSafe => 'All ages';

  @override
  String get contentRatingR18 => 'NSFW';

  @override
  String get relativeTimeJustNow => 'Just now';

  @override
  String relativeTimeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String relativeTimeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String relativeTimeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String readingProgressPage(int page) {
    return 'Page $page';
  }

  @override
  String get historyDeleteRecord => 'Delete entry';

  @override
  String bootstrapStartupFailed(String error) {
    return 'Startup failed: $error';
  }
}
