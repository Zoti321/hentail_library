import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @libraryTitle.
  ///
  /// In zh, this message translates to:
  /// **'漫画库'**
  String get libraryTitle;

  /// No description provided for @libraryEmptyTitle.
  ///
  /// In zh, this message translates to:
  /// **'暂无漫画'**
  String get libraryEmptyTitle;

  /// No description provided for @libraryEmptyHint.
  ///
  /// In zh, this message translates to:
  /// **'请先在「选中路径」中添加路径并扫描'**
  String get libraryEmptyHint;

  /// No description provided for @librarySeriesEmptyTitle.
  ///
  /// In zh, this message translates to:
  /// **'暂无系列'**
  String get librarySeriesEmptyTitle;

  /// No description provided for @librarySeriesEmptyHint.
  ///
  /// In zh, this message translates to:
  /// **'系列由扫描结果自动生成，添加路径并扫描后即可出现'**
  String get librarySeriesEmptyHint;

  /// No description provided for @libraryNoMatchTitle.
  ///
  /// In zh, this message translates to:
  /// **'没有匹配结果'**
  String get libraryNoMatchTitle;

  /// No description provided for @libraryNoMatchFilterHintComics.
  ///
  /// In zh, this message translates to:
  /// **'当前筛选条件下没有漫画'**
  String get libraryNoMatchFilterHintComics;

  /// No description provided for @libraryNoMatchFilterHintSeries.
  ///
  /// In zh, this message translates to:
  /// **'当前筛选条件下没有系列'**
  String get libraryNoMatchFilterHintSeries;

  /// No description provided for @comicCount.
  ///
  /// In zh, this message translates to:
  /// **'{count, plural, =0{0 本} other{{count} 本}}'**
  String comicCount(int count);

  /// No description provided for @settingsLanguageLabel.
  ///
  /// In zh, this message translates to:
  /// **'界面语言'**
  String get settingsLanguageLabel;

  /// No description provided for @localePreferenceSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get localePreferenceSystem;

  /// No description provided for @localePreferenceZhCn.
  ///
  /// In zh, this message translates to:
  /// **'中文'**
  String get localePreferenceZhCn;

  /// No description provided for @localePreferenceEn.
  ///
  /// In zh, this message translates to:
  /// **'English'**
  String get localePreferenceEn;

  /// No description provided for @settingsThemeLabel.
  ///
  /// In zh, this message translates to:
  /// **'应用主题'**
  String get settingsThemeLabel;

  /// No description provided for @themePreferenceSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get themePreferenceSystem;

  /// No description provided for @themePreferenceLight.
  ///
  /// In zh, this message translates to:
  /// **'浅色'**
  String get themePreferenceLight;

  /// No description provided for @themePreferenceDark.
  ///
  /// In zh, this message translates to:
  /// **'深色'**
  String get themePreferenceDark;

  /// No description provided for @navHome.
  ///
  /// In zh, this message translates to:
  /// **'首页'**
  String get navHome;

  /// No description provided for @navMetadata.
  ///
  /// In zh, this message translates to:
  /// **'管理'**
  String get navMetadata;

  /// No description provided for @navHistory.
  ///
  /// In zh, this message translates to:
  /// **'历史'**
  String get navHistory;

  /// No description provided for @navSettings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get navSettings;

  /// No description provided for @pageTitleReader.
  ///
  /// In zh, this message translates to:
  /// **'阅读'**
  String get pageTitleReader;

  /// No description provided for @pageTitleComicDetail.
  ///
  /// In zh, this message translates to:
  /// **'漫画详情'**
  String get pageTitleComicDetail;

  /// No description provided for @pageTitleSeriesDetail.
  ///
  /// In zh, this message translates to:
  /// **'系列详情'**
  String get pageTitleSeriesDetail;

  /// No description provided for @pageTitlePaths.
  ///
  /// In zh, this message translates to:
  /// **'库路径'**
  String get pageTitlePaths;

  /// No description provided for @pageTitleSearchResults.
  ///
  /// In zh, this message translates to:
  /// **'搜索结果'**
  String get pageTitleSearchResults;

  /// No description provided for @pageTitleNotFound.
  ///
  /// In zh, this message translates to:
  /// **'页面不存在'**
  String get pageTitleNotFound;

  /// No description provided for @shellOpenNavMenu.
  ///
  /// In zh, this message translates to:
  /// **'打开导航菜单'**
  String get shellOpenNavMenu;

  /// No description provided for @shellLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载失败'**
  String get shellLoadFailed;

  /// No description provided for @shellLoading.
  ///
  /// In zh, this message translates to:
  /// **'加载中…'**
  String get shellLoading;

  /// No description provided for @shellBack.
  ///
  /// In zh, this message translates to:
  /// **'返回'**
  String get shellBack;

  /// No description provided for @shellBackToSettings.
  ///
  /// In zh, this message translates to:
  /// **'返回设置'**
  String get shellBackToSettings;

  /// No description provided for @shellRetry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get shellRetry;

  /// No description provided for @shellRetrying.
  ///
  /// In zh, this message translates to:
  /// **'重试中…'**
  String get shellRetrying;

  /// No description provided for @shellProcessing.
  ///
  /// In zh, this message translates to:
  /// **'处理中…'**
  String get shellProcessing;

  /// No description provided for @homeTitle.
  ///
  /// In zh, this message translates to:
  /// **'首页'**
  String get homeTitle;

  /// No description provided for @homeScanLibrary.
  ///
  /// In zh, this message translates to:
  /// **'扫描漫画库'**
  String get homeScanLibrary;

  /// No description provided for @homeGreetingLateNight.
  ///
  /// In zh, this message translates to:
  /// **'凌晨好'**
  String get homeGreetingLateNight;

  /// No description provided for @homeGreetingEarlyMorning.
  ///
  /// In zh, this message translates to:
  /// **'早上好'**
  String get homeGreetingEarlyMorning;

  /// No description provided for @homeGreetingMorning.
  ///
  /// In zh, this message translates to:
  /// **'上午好'**
  String get homeGreetingMorning;

  /// No description provided for @homeGreetingNoon.
  ///
  /// In zh, this message translates to:
  /// **'中午好'**
  String get homeGreetingNoon;

  /// No description provided for @homeGreetingAfternoon.
  ///
  /// In zh, this message translates to:
  /// **'下午好'**
  String get homeGreetingAfternoon;

  /// No description provided for @homeGreetingEvening.
  ///
  /// In zh, this message translates to:
  /// **'晚上好'**
  String get homeGreetingEvening;

  /// No description provided for @homeGreetingLate.
  ///
  /// In zh, this message translates to:
  /// **'夜深了'**
  String get homeGreetingLate;

  /// No description provided for @homeGreetingReader.
  ///
  /// In zh, this message translates to:
  /// **'{greeting}，读者'**
  String homeGreetingReader(String greeting);

  /// No description provided for @homeEmptyTitle.
  ///
  /// In zh, this message translates to:
  /// **'尚未导入漫画'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyHint.
  ///
  /// In zh, this message translates to:
  /// **'请先在设置中添加库文件夹并扫描；若已配置，可检查选中路径或重新扫描。'**
  String get homeEmptyHint;

  /// No description provided for @pathsTitle.
  ///
  /// In zh, this message translates to:
  /// **'选中路径'**
  String get pathsTitle;

  /// No description provided for @homeStatSeries.
  ///
  /// In zh, this message translates to:
  /// **'系列'**
  String get homeStatSeries;

  /// No description provided for @homeStatTags.
  ///
  /// In zh, this message translates to:
  /// **'标签'**
  String get homeStatTags;

  /// No description provided for @homeStatAuthors.
  ///
  /// In zh, this message translates to:
  /// **'作者'**
  String get homeStatAuthors;

  /// No description provided for @homeComicTotal.
  ///
  /// In zh, this message translates to:
  /// **'共 {count, plural, other{{count} 本}}'**
  String homeComicTotal(int count);

  /// No description provided for @homeSeriesCount.
  ///
  /// In zh, this message translates to:
  /// **'{count, plural, other{{count} 个系列}}'**
  String homeSeriesCount(int count);

  /// No description provided for @homeTagCount.
  ///
  /// In zh, this message translates to:
  /// **'{count, plural, other{{count} 个标签}}'**
  String homeTagCount(int count);

  /// No description provided for @homeAuthorCount.
  ///
  /// In zh, this message translates to:
  /// **'{count, plural, other{{count} 位}}'**
  String homeAuthorCount(int count);

  /// No description provided for @homeNoAuthors.
  ///
  /// In zh, this message translates to:
  /// **'暂无作者'**
  String get homeNoAuthors;

  /// No description provided for @homeContinueReading.
  ///
  /// In zh, this message translates to:
  /// **'继续阅读'**
  String get homeContinueReading;

  /// No description provided for @homeNoReadingHistory.
  ///
  /// In zh, this message translates to:
  /// **'暂无阅读记录，'**
  String get homeNoReadingHistory;

  /// No description provided for @homeGoToLibrary.
  ///
  /// In zh, this message translates to:
  /// **'去漫画库'**
  String get homeGoToLibrary;

  /// No description provided for @historyTitle.
  ///
  /// In zh, this message translates to:
  /// **'阅读历史'**
  String get historyTitle;

  /// No description provided for @historyClearAction.
  ///
  /// In zh, this message translates to:
  /// **'清空阅读历史'**
  String get historyClearAction;

  /// No description provided for @historyClearedToast.
  ///
  /// In zh, this message translates to:
  /// **'已清空阅读历史'**
  String get historyClearedToast;

  /// No description provided for @historyRecordSummary.
  ///
  /// In zh, this message translates to:
  /// **'{count, plural, other{{count} 条记录 • 最长保留 30 天}}'**
  String historyRecordSummary(int count);

  /// No description provided for @historySearchHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索历史记录...'**
  String get historySearchHint;

  /// No description provided for @historyEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无阅读历史'**
  String get historyEmpty;

  /// No description provided for @historyNoMatch.
  ///
  /// In zh, this message translates to:
  /// **'没有匹配的历史记录'**
  String get historyNoMatch;

  /// No description provided for @historyDeletedToast.
  ///
  /// In zh, this message translates to:
  /// **'已删除记录'**
  String get historyDeletedToast;

  /// No description provided for @pathsSavedHeading.
  ///
  /// In zh, this message translates to:
  /// **'已保存路径'**
  String get pathsSavedHeading;

  /// No description provided for @pathsTotalCount.
  ///
  /// In zh, this message translates to:
  /// **'{count, plural, other{共 {count} 项}}'**
  String pathsTotalCount(int count);

  /// No description provided for @pathsEmptyHint.
  ///
  /// In zh, this message translates to:
  /// **'暂无路径，请添加文件夹'**
  String get pathsEmptyHint;

  /// No description provided for @pathsAddButton.
  ///
  /// In zh, this message translates to:
  /// **'添加路径'**
  String get pathsAddButton;

  /// No description provided for @pathsAddedOneToast.
  ///
  /// In zh, this message translates to:
  /// **'已添加 1 个路径'**
  String get pathsAddedOneToast;

  /// No description provided for @pathsRemovedToast.
  ///
  /// In zh, this message translates to:
  /// **'已移除路径'**
  String get pathsRemovedToast;

  /// No description provided for @pathsRemoveAction.
  ///
  /// In zh, this message translates to:
  /// **'移除路径'**
  String get pathsRemoveAction;

  /// No description provided for @pathsLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'路径加载失败'**
  String get pathsLoadFailed;

  /// No description provided for @notFoundTitle.
  ///
  /// In zh, this message translates to:
  /// **'页面不存在'**
  String get notFoundTitle;

  /// No description provided for @notFoundHint.
  ///
  /// In zh, this message translates to:
  /// **'你访问的链接可能已失效，或页面已被移除。'**
  String get notFoundHint;

  /// No description provided for @notFoundGoHome.
  ///
  /// In zh, this message translates to:
  /// **'返回首页'**
  String get notFoundGoHome;

  /// No description provided for @notFoundGoLibrary.
  ///
  /// In zh, this message translates to:
  /// **'去漫画库'**
  String get notFoundGoLibrary;

  /// No description provided for @settingsGroupPersonalization.
  ///
  /// In zh, this message translates to:
  /// **'个性化'**
  String get settingsGroupPersonalization;

  /// No description provided for @settingsGroupLibrary.
  ///
  /// In zh, this message translates to:
  /// **'漫画库'**
  String get settingsGroupLibrary;

  /// No description provided for @settingsGroupDiagnostics.
  ///
  /// In zh, this message translates to:
  /// **'诊断与支持'**
  String get settingsGroupDiagnostics;

  /// No description provided for @settingsGroupAbout.
  ///
  /// In zh, this message translates to:
  /// **'关于'**
  String get settingsGroupAbout;

  /// No description provided for @settingsDiagnosticModeLabel.
  ///
  /// In zh, this message translates to:
  /// **'详细诊断'**
  String get settingsDiagnosticModeLabel;

  /// No description provided for @settingsDiagnosticModeDescriptionEnabled.
  ///
  /// In zh, this message translates to:
  /// **'已开启：Dart 与 Rust 记录更详细日志'**
  String get settingsDiagnosticModeDescriptionEnabled;

  /// No description provided for @settingsDiagnosticModeDescriptionDisabled.
  ///
  /// In zh, this message translates to:
  /// **'临时提高日志详细程度，便于复现问题'**
  String get settingsDiagnosticModeDescriptionDisabled;

  /// No description provided for @settingsDiagnosticModeEnabledBadge.
  ///
  /// In zh, this message translates to:
  /// **'已开启'**
  String get settingsDiagnosticModeEnabledBadge;

  /// No description provided for @settingsExportLogsLabel.
  ///
  /// In zh, this message translates to:
  /// **'导出日志'**
  String get settingsExportLogsLabel;

  /// No description provided for @settingsExportLogsDescription.
  ///
  /// In zh, this message translates to:
  /// **'打包应用与核心日志，便于问题反馈'**
  String get settingsExportLogsDescription;

  /// No description provided for @settingsLibraryLocationLabel.
  ///
  /// In zh, this message translates to:
  /// **'库位置'**
  String get settingsLibraryLocationLabel;

  /// No description provided for @settingsAutoScanLabel.
  ///
  /// In zh, this message translates to:
  /// **'自动扫描'**
  String get settingsAutoScanLabel;

  /// No description provided for @settingsAutoUpdateLabel.
  ///
  /// In zh, this message translates to:
  /// **'自动更新'**
  String get settingsAutoUpdateLabel;

  /// No description provided for @settingsCurrentVersion.
  ///
  /// In zh, this message translates to:
  /// **'当前版本 v{version}'**
  String settingsCurrentVersion(String version);

  /// No description provided for @settingsCurrentVersionLoading.
  ///
  /// In zh, this message translates to:
  /// **'当前版本 …'**
  String get settingsCurrentVersionLoading;

  /// No description provided for @settingsCheckForUpdatesLabel.
  ///
  /// In zh, this message translates to:
  /// **'检查更新'**
  String get settingsCheckForUpdatesLabel;

  /// No description provided for @settingsUpdateCheckFailed.
  ///
  /// In zh, this message translates to:
  /// **'检查更新失败，请稍后重试'**
  String get settingsUpdateCheckFailed;

  /// No description provided for @settingsUpdateUpToDate.
  ///
  /// In zh, this message translates to:
  /// **'当前已是最新版本'**
  String get settingsUpdateUpToDate;

  /// No description provided for @libraryTabComics.
  ///
  /// In zh, this message translates to:
  /// **'漫画'**
  String get libraryTabComics;

  /// No description provided for @libraryTabSeries.
  ///
  /// In zh, this message translates to:
  /// **'系列'**
  String get libraryTabSeries;

  /// No description provided for @librarySeriesCount.
  ///
  /// In zh, this message translates to:
  /// **'{count, plural, other{{count} 个系列}}'**
  String librarySeriesCount(int count);

  /// No description provided for @libraryManageScanPaths.
  ///
  /// In zh, this message translates to:
  /// **'管理扫描路径'**
  String get libraryManageScanPaths;

  /// No description provided for @librarySearchHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索…'**
  String get librarySearchHint;

  /// No description provided for @librarySearchKeywordEmpty.
  ///
  /// In zh, this message translates to:
  /// **'关键词不能为空'**
  String get librarySearchKeywordEmpty;

  /// No description provided for @libraryFilterSortTooltip.
  ///
  /// In zh, this message translates to:
  /// **'筛选与排序'**
  String get libraryFilterSortTooltip;

  /// No description provided for @libraryFilterSortSemantic.
  ///
  /// In zh, this message translates to:
  /// **'打开筛选与排序'**
  String get libraryFilterSortSemantic;

  /// No description provided for @libraryPageSizeTooltip.
  ///
  /// In zh, this message translates to:
  /// **'每页数量'**
  String get libraryPageSizeTooltip;

  /// No description provided for @libraryPageSizeSemantic.
  ///
  /// In zh, this message translates to:
  /// **'设置每页数量'**
  String get libraryPageSizeSemantic;

  /// No description provided for @libraryScanCancelledToast.
  ///
  /// In zh, this message translates to:
  /// **'已取消扫描'**
  String get libraryScanCancelledToast;

  /// No description provided for @libraryScanningDeep.
  ///
  /// In zh, this message translates to:
  /// **'正在深度扫描…'**
  String get libraryScanningDeep;

  /// No description provided for @libraryScanning.
  ///
  /// In zh, this message translates to:
  /// **'正在扫描…'**
  String get libraryScanning;

  /// No description provided for @libraryCancelScan.
  ///
  /// In zh, this message translates to:
  /// **'取消扫描'**
  String get libraryCancelScan;

  /// No description provided for @libraryMoreActions.
  ///
  /// In zh, this message translates to:
  /// **'更多操作'**
  String get libraryMoreActions;

  /// No description provided for @libraryMoreActionsSemantic.
  ///
  /// In zh, this message translates to:
  /// **'打开更多操作'**
  String get libraryMoreActionsSemantic;

  /// No description provided for @libraryRefresh.
  ///
  /// In zh, this message translates to:
  /// **'刷新'**
  String get libraryRefresh;

  /// No description provided for @libraryScan.
  ///
  /// In zh, this message translates to:
  /// **'扫描'**
  String get libraryScan;

  /// No description provided for @libraryDeepScan.
  ///
  /// In zh, this message translates to:
  /// **'深度扫描'**
  String get libraryDeepScan;

  /// No description provided for @libraryScrollToTop.
  ///
  /// In zh, this message translates to:
  /// **'回到顶部'**
  String get libraryScrollToTop;

  /// No description provided for @libraryFilterSection.
  ///
  /// In zh, this message translates to:
  /// **'筛选'**
  String get libraryFilterSection;

  /// No description provided for @librarySortSection.
  ///
  /// In zh, this message translates to:
  /// **'排序'**
  String get librarySortSection;

  /// No description provided for @libraryAgeRestrictionFilter.
  ///
  /// In zh, this message translates to:
  /// **'年龄限制'**
  String get libraryAgeRestrictionFilter;

  /// No description provided for @libraryMediaTypeFilter.
  ///
  /// In zh, this message translates to:
  /// **'媒体类型'**
  String get libraryMediaTypeFilter;

  /// No description provided for @libraryComingSoon.
  ///
  /// In zh, this message translates to:
  /// **'即将推出'**
  String get libraryComingSoon;

  /// No description provided for @libraryComicSortTitle.
  ///
  /// In zh, this message translates to:
  /// **'标题'**
  String get libraryComicSortTitle;

  /// No description provided for @libraryComicSortCreatedAt.
  ///
  /// In zh, this message translates to:
  /// **'添加时间'**
  String get libraryComicSortCreatedAt;

  /// No description provided for @libraryComicSortLastUpdatedAt.
  ///
  /// In zh, this message translates to:
  /// **'更新时间'**
  String get libraryComicSortLastUpdatedAt;

  /// No description provided for @libraryComicSortPublishedAt.
  ///
  /// In zh, this message translates to:
  /// **'发布日期'**
  String get libraryComicSortPublishedAt;

  /// No description provided for @libraryComicSortReadAt.
  ///
  /// In zh, this message translates to:
  /// **'阅读日期'**
  String get libraryComicSortReadAt;

  /// No description provided for @libraryComicSortFileSize.
  ///
  /// In zh, this message translates to:
  /// **'文件大小'**
  String get libraryComicSortFileSize;

  /// No description provided for @libraryComicSortPageCount.
  ///
  /// In zh, this message translates to:
  /// **'页数'**
  String get libraryComicSortPageCount;

  /// No description provided for @librarySeriesSortName.
  ///
  /// In zh, this message translates to:
  /// **'名称'**
  String get librarySeriesSortName;

  /// No description provided for @librarySeriesSortComicCount.
  ///
  /// In zh, this message translates to:
  /// **'漫画数量'**
  String get librarySeriesSortComicCount;

  /// No description provided for @librarySeriesSortRandom.
  ///
  /// In zh, this message translates to:
  /// **'随机'**
  String get librarySeriesSortRandom;

  /// No description provided for @filterAgeUnrestricted.
  ///
  /// In zh, this message translates to:
  /// **'不限'**
  String get filterAgeUnrestricted;

  /// No description provided for @filterAgeAllAges.
  ///
  /// In zh, this message translates to:
  /// **'全年龄'**
  String get filterAgeAllAges;

  /// No description provided for @filterAgeR18Only.
  ///
  /// In zh, this message translates to:
  /// **'R18'**
  String get filterAgeR18Only;

  /// No description provided for @filterMediaTypePdf.
  ///
  /// In zh, this message translates to:
  /// **'PDF'**
  String get filterMediaTypePdf;

  /// No description provided for @filterMediaTypeEpub.
  ///
  /// In zh, this message translates to:
  /// **'EPUB'**
  String get filterMediaTypeEpub;

  /// No description provided for @filterMediaTypeArchive.
  ///
  /// In zh, this message translates to:
  /// **'压缩包'**
  String get filterMediaTypeArchive;

  /// No description provided for @libraryScanComplete.
  ///
  /// In zh, this message translates to:
  /// **'扫描完成'**
  String get libraryScanComplete;

  /// No description provided for @libraryDeepScanComplete.
  ///
  /// In zh, this message translates to:
  /// **'深度扫描完成'**
  String get libraryDeepScanComplete;

  /// No description provided for @libraryScanCompleteNoRoots.
  ///
  /// In zh, this message translates to:
  /// **'扫描完成：未配置扫描路径'**
  String get libraryScanCompleteNoRoots;

  /// No description provided for @libraryDeepScanCompleteNoRoots.
  ///
  /// In zh, this message translates to:
  /// **'深度扫描完成：未配置扫描路径'**
  String get libraryDeepScanCompleteNoRoots;

  /// No description provided for @libraryScanCompleteCleared.
  ///
  /// In zh, this message translates to:
  /// **'扫描完成：已移除 {count} 项'**
  String libraryScanCompleteCleared(int count);

  /// No description provided for @libraryDeepScanCompleteCleared.
  ///
  /// In zh, this message translates to:
  /// **'深度扫描完成：已移除 {count} 项'**
  String libraryDeepScanCompleteCleared(int count);

  /// No description provided for @libraryScanCompleteStats.
  ///
  /// In zh, this message translates to:
  /// **'扫描完成：新增 {added}，移除 {removed}，保留 {kept}'**
  String libraryScanCompleteStats(int added, int removed, int kept);

  /// No description provided for @libraryDeepScanCompleteStats.
  ///
  /// In zh, this message translates to:
  /// **'深度扫描完成：新增 {added}，移除 {removed}，保留 {kept}'**
  String libraryDeepScanCompleteStats(int added, int removed, int kept);

  /// No description provided for @searchResultsTitle.
  ///
  /// In zh, this message translates to:
  /// **'搜索结果'**
  String get searchResultsTitle;

  /// No description provided for @searchResultsForQuery.
  ///
  /// In zh, this message translates to:
  /// **'\"{query}\"的搜索结果'**
  String searchResultsForQuery(String query);

  /// No description provided for @searchEnterKeyword.
  ///
  /// In zh, this message translates to:
  /// **'请输入关键词后按回车搜索'**
  String get searchEnterKeyword;

  /// No description provided for @searchLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载失败：{error}'**
  String searchLoadFailed(String error);

  /// No description provided for @searchBackToLibrary.
  ///
  /// In zh, this message translates to:
  /// **'返回漫画库'**
  String get searchBackToLibrary;

  /// No description provided for @searchScrollLeft.
  ///
  /// In zh, this message translates to:
  /// **'向左滚动'**
  String get searchScrollLeft;

  /// No description provided for @searchScrollRight.
  ///
  /// In zh, this message translates to:
  /// **'向右滚动'**
  String get searchScrollRight;

  /// No description provided for @comicDetailPageCount.
  ///
  /// In zh, this message translates to:
  /// **'{count, plural, other{{count} 页}}'**
  String comicDetailPageCount(int count);

  /// No description provided for @comicDetailAuthors.
  ///
  /// In zh, this message translates to:
  /// **'作者'**
  String get comicDetailAuthors;

  /// No description provided for @comicDetailTags.
  ///
  /// In zh, this message translates to:
  /// **'标签'**
  String get comicDetailTags;

  /// No description provided for @comicDetailResourceFormat.
  ///
  /// In zh, this message translates to:
  /// **'资源格式'**
  String get comicDetailResourceFormat;

  /// No description provided for @comicDetailResourceSize.
  ///
  /// In zh, this message translates to:
  /// **'资源大小'**
  String get comicDetailResourceSize;

  /// No description provided for @comicDetailResourcePath.
  ///
  /// In zh, this message translates to:
  /// **'资源路径'**
  String get comicDetailResourcePath;

  /// No description provided for @comicDetailAddedAt.
  ///
  /// In zh, this message translates to:
  /// **'添加时间'**
  String get comicDetailAddedAt;

  /// No description provided for @comicDetailUpdatedAt.
  ///
  /// In zh, this message translates to:
  /// **'更新时间'**
  String get comicDetailUpdatedAt;

  /// No description provided for @comicDetailRead.
  ///
  /// In zh, this message translates to:
  /// **'阅读'**
  String get comicDetailRead;

  /// No description provided for @comicDetailReadIncognito.
  ///
  /// In zh, this message translates to:
  /// **'无痕阅读'**
  String get comicDetailReadIncognito;

  /// No description provided for @comicDetailEditMetadata.
  ///
  /// In zh, this message translates to:
  /// **'编辑元数据'**
  String get comicDetailEditMetadata;

  /// No description provided for @comicDetailShowInExplorer.
  ///
  /// In zh, this message translates to:
  /// **'在资源管理器中显示'**
  String get comicDetailShowInExplorer;

  /// No description provided for @comicDetailShowInExplorerFailed.
  ///
  /// In zh, this message translates to:
  /// **'无法在文件资源管理器中显示该项目'**
  String get comicDetailShowInExplorerFailed;

  /// No description provided for @comicDetailDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get comicDetailDelete;

  /// No description provided for @comicDetailDeleteTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除漫画？'**
  String get comicDetailDeleteTitle;

  /// No description provided for @comicDetailDeleteConfirm.
  ///
  /// In zh, this message translates to:
  /// **'将删除「{title}」。此操作不可撤销。'**
  String comicDetailDeleteConfirm(String title);

  /// No description provided for @comicDetailCancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get comicDetailCancel;

  /// No description provided for @comicDetailDeletedToast.
  ///
  /// In zh, this message translates to:
  /// **'已删除漫画'**
  String get comicDetailDeletedToast;

  /// No description provided for @comicDetailNotFound.
  ///
  /// In zh, this message translates to:
  /// **'漫画不存在或已移除'**
  String get comicDetailNotFound;

  /// No description provided for @comicDetailLoadFailedRetry.
  ///
  /// In zh, this message translates to:
  /// **'加载失败，请重试'**
  String get comicDetailLoadFailedRetry;

  /// No description provided for @comicDetailGoToLibrary.
  ///
  /// In zh, this message translates to:
  /// **'前往漫画库'**
  String get comicDetailGoToLibrary;

  /// No description provided for @comicDetailSeriesNavConflict.
  ///
  /// In zh, this message translates to:
  /// **'系列数据异常：该漫画同时属于多个系列，无法使用系列导航'**
  String get comicDetailSeriesNavConflict;

  /// No description provided for @comicDetailSeriesPrev.
  ///
  /// In zh, this message translates to:
  /// **'上一本'**
  String get comicDetailSeriesPrev;

  /// No description provided for @comicDetailSeriesPrevSemantic.
  ///
  /// In zh, this message translates to:
  /// **'系列上一本'**
  String get comicDetailSeriesPrevSemantic;

  /// No description provided for @comicDetailSeriesCatalog.
  ///
  /// In zh, this message translates to:
  /// **'系列目录'**
  String get comicDetailSeriesCatalog;

  /// No description provided for @comicDetailSeriesNext.
  ///
  /// In zh, this message translates to:
  /// **'下一本'**
  String get comicDetailSeriesNext;

  /// No description provided for @comicDetailSeriesNextSemantic.
  ///
  /// In zh, this message translates to:
  /// **'系列下一本'**
  String get comicDetailSeriesNextSemantic;

  /// No description provided for @seriesDetailEdit.
  ///
  /// In zh, this message translates to:
  /// **'编辑系列'**
  String get seriesDetailEdit;

  /// No description provided for @seriesDetailNoComics.
  ///
  /// In zh, this message translates to:
  /// **'系列内暂无漫画'**
  String get seriesDetailNoComics;

  /// No description provided for @seriesDetailComicsLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'漫画列表加载失败'**
  String get seriesDetailComicsLoadFailed;

  /// No description provided for @seriesDetailUnknown.
  ///
  /// In zh, this message translates to:
  /// **'未知系列'**
  String get seriesDetailUnknown;

  /// No description provided for @seriesDetailNotFound.
  ///
  /// In zh, this message translates to:
  /// **'未找到系列「{name}」'**
  String seriesDetailNotFound(String name);

  /// No description provided for @seriesDetailVolumeCount.
  ///
  /// In zh, this message translates to:
  /// **'{count, plural, other{{count} 本}}'**
  String seriesDetailVolumeCount(int count);

  /// No description provided for @seriesDetailVolumeProgress.
  ///
  /// In zh, this message translates to:
  /// **'{current} / 共 {total} 本'**
  String seriesDetailVolumeProgress(int current, int total);

  /// No description provided for @seriesDetailPaginationPage.
  ///
  /// In zh, this message translates to:
  /// **'第 {page} / {totalPages} 页'**
  String seriesDetailPaginationPage(int page, int totalPages);

  /// No description provided for @seriesDetailPaginationFirst.
  ///
  /// In zh, this message translates to:
  /// **'首页'**
  String get seriesDetailPaginationFirst;

  /// No description provided for @seriesDetailPaginationPrevious.
  ///
  /// In zh, this message translates to:
  /// **'上一页'**
  String get seriesDetailPaginationPrevious;

  /// No description provided for @seriesDetailPaginationNext.
  ///
  /// In zh, this message translates to:
  /// **'下一页'**
  String get seriesDetailPaginationNext;

  /// No description provided for @seriesDetailPaginationLast.
  ///
  /// In zh, this message translates to:
  /// **'末页'**
  String get seriesDetailPaginationLast;

  /// No description provided for @serializationStatusOngoing.
  ///
  /// In zh, this message translates to:
  /// **'连载中'**
  String get serializationStatusOngoing;

  /// No description provided for @serializationStatusEnded.
  ///
  /// In zh, this message translates to:
  /// **'已完结'**
  String get serializationStatusEnded;

  /// No description provided for @serializationStatusHiatus.
  ///
  /// In zh, this message translates to:
  /// **'休刊'**
  String get serializationStatusHiatus;

  /// No description provided for @serializationStatusUnknown.
  ///
  /// In zh, this message translates to:
  /// **'未知'**
  String get serializationStatusUnknown;

  /// No description provided for @readerSettingsTitle.
  ///
  /// In zh, this message translates to:
  /// **'阅读设置'**
  String get readerSettingsTitle;

  /// No description provided for @readerSettingsClose.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get readerSettingsClose;

  /// No description provided for @readerSettingsGeneral.
  ///
  /// In zh, this message translates to:
  /// **'常规'**
  String get readerSettingsGeneral;

  /// No description provided for @readerSettingsReadingMode.
  ///
  /// In zh, this message translates to:
  /// **'阅读模式'**
  String get readerSettingsReadingMode;

  /// No description provided for @readerSettingsAutoPlay.
  ///
  /// In zh, this message translates to:
  /// **'自动播放'**
  String get readerSettingsAutoPlay;

  /// No description provided for @readerSettingsPlayInterval.
  ///
  /// In zh, this message translates to:
  /// **'播放间隔'**
  String get readerSettingsPlayInterval;

  /// No description provided for @readerSettingsSecondsSuffix.
  ///
  /// In zh, this message translates to:
  /// **'秒'**
  String get readerSettingsSecondsSuffix;

  /// No description provided for @readerSettingsWebtoonMode.
  ///
  /// In zh, this message translates to:
  /// **'Webtoon 模式'**
  String get readerSettingsWebtoonMode;

  /// No description provided for @readerSettingsPagedOptions.
  ///
  /// In zh, this message translates to:
  /// **'分页阅读器选项'**
  String get readerSettingsPagedOptions;

  /// No description provided for @readerSettingsHorizontalMargin.
  ///
  /// In zh, this message translates to:
  /// **'左右边距'**
  String get readerSettingsHorizontalMargin;

  /// No description provided for @readerSettingsMarginNone.
  ///
  /// In zh, this message translates to:
  /// **'无 (0%)'**
  String get readerSettingsMarginNone;

  /// No description provided for @readerSettingsMarginPercent.
  ///
  /// In zh, this message translates to:
  /// **'{percent}%'**
  String readerSettingsMarginPercent(int percent);

  /// No description provided for @readerSettingsZoomMode.
  ///
  /// In zh, this message translates to:
  /// **'缩放模式'**
  String get readerSettingsZoomMode;

  /// No description provided for @readerSettingsPageLayout.
  ///
  /// In zh, this message translates to:
  /// **'页面布局'**
  String get readerSettingsPageLayout;

  /// No description provided for @readingModeCategoryPaged.
  ///
  /// In zh, this message translates to:
  /// **'翻页'**
  String get readingModeCategoryPaged;

  /// No description provided for @readingModeCategoryWebtoon.
  ///
  /// In zh, this message translates to:
  /// **'Webtoon'**
  String get readingModeCategoryWebtoon;

  /// No description provided for @readingModePaged.
  ///
  /// In zh, this message translates to:
  /// **'翻页'**
  String get readingModePaged;

  /// No description provided for @readingModeWebtoon.
  ///
  /// In zh, this message translates to:
  /// **'Webtoon'**
  String get readingModeWebtoon;

  /// No description provided for @readingModeDualPage.
  ///
  /// In zh, this message translates to:
  /// **'双页'**
  String get readingModeDualPage;

  /// No description provided for @readingModeDualPageNoCover.
  ///
  /// In zh, this message translates to:
  /// **'双页（封面独立）'**
  String get readingModeDualPageNoCover;

  /// No description provided for @readingModePagedSingle.
  ///
  /// In zh, this message translates to:
  /// **'单页'**
  String get readingModePagedSingle;

  /// No description provided for @readingModePagedDual.
  ///
  /// In zh, this message translates to:
  /// **'双页'**
  String get readingModePagedDual;

  /// No description provided for @readingModePagedDualNoCover.
  ///
  /// In zh, this message translates to:
  /// **'双页（封面独立）'**
  String get readingModePagedDualNoCover;

  /// No description provided for @readingModeWebtoonFitWidth.
  ///
  /// In zh, this message translates to:
  /// **'适应宽度'**
  String get readingModeWebtoonFitWidth;

  /// No description provided for @readingModeWebtoonOriginalSize.
  ///
  /// In zh, this message translates to:
  /// **'原始尺寸'**
  String get readingModeWebtoonOriginalSize;

  /// No description provided for @readerSetComicCover.
  ///
  /// In zh, this message translates to:
  /// **'将当前页设为漫画封面'**
  String get readerSetComicCover;

  /// No description provided for @readerSetSeriesCover.
  ///
  /// In zh, this message translates to:
  /// **'将当前页设为系列封面'**
  String get readerSetSeriesCover;

  /// No description provided for @readerMore.
  ///
  /// In zh, this message translates to:
  /// **'更多'**
  String get readerMore;

  /// No description provided for @readerMoreSemantic.
  ///
  /// In zh, this message translates to:
  /// **'更多阅读选项'**
  String get readerMoreSemantic;

  /// No description provided for @readerStateNotReady.
  ///
  /// In zh, this message translates to:
  /// **'阅读状态未就绪'**
  String get readerStateNotReady;

  /// No description provided for @readerComicCoverSet.
  ///
  /// In zh, this message translates to:
  /// **'已设为漫画封面'**
  String get readerComicCoverSet;

  /// No description provided for @readerComicCoverSetFailed.
  ///
  /// In zh, this message translates to:
  /// **'设置漫画封面失败：{error}'**
  String readerComicCoverSetFailed(String error);

  /// No description provided for @readerSeriesCoverSet.
  ///
  /// In zh, this message translates to:
  /// **'已设为系列封面'**
  String get readerSeriesCoverSet;

  /// No description provided for @readerSeriesCoverSetFailed.
  ///
  /// In zh, this message translates to:
  /// **'设置系列封面失败：{error}'**
  String readerSeriesCoverSetFailed(String error);

  /// No description provided for @readerBackSemantic.
  ///
  /// In zh, this message translates to:
  /// **'返回上一页'**
  String get readerBackSemantic;

  /// No description provided for @readerExitFullscreen.
  ///
  /// In zh, this message translates to:
  /// **'退出全屏'**
  String get readerExitFullscreen;

  /// No description provided for @readerEnterFullscreen.
  ///
  /// In zh, this message translates to:
  /// **'全屏'**
  String get readerEnterFullscreen;

  /// No description provided for @readerExitFullscreenSemantic.
  ///
  /// In zh, this message translates to:
  /// **'退出全屏'**
  String get readerExitFullscreenSemantic;

  /// No description provided for @readerEnterFullscreenSemantic.
  ///
  /// In zh, this message translates to:
  /// **'进入全屏'**
  String get readerEnterFullscreenSemantic;

  /// No description provided for @readerOpenSettingsSemantic.
  ///
  /// In zh, this message translates to:
  /// **'打开阅读设置'**
  String get readerOpenSettingsSemantic;

  /// No description provided for @readerSeriesCatalog.
  ///
  /// In zh, this message translates to:
  /// **'系列目录'**
  String get readerSeriesCatalog;

  /// No description provided for @readerPrevVolume.
  ///
  /// In zh, this message translates to:
  /// **'上一卷'**
  String get readerPrevVolume;

  /// No description provided for @readerPrevVolumeSemantic.
  ///
  /// In zh, this message translates to:
  /// **'系列上一卷'**
  String get readerPrevVolumeSemantic;

  /// No description provided for @readerFirstPage.
  ///
  /// In zh, this message translates to:
  /// **'首页'**
  String get readerFirstPage;

  /// No description provided for @readerFirstPageSemantic.
  ///
  /// In zh, this message translates to:
  /// **'跳转到首页'**
  String get readerFirstPageSemantic;

  /// No description provided for @readerNextVolume.
  ///
  /// In zh, this message translates to:
  /// **'下一卷'**
  String get readerNextVolume;

  /// No description provided for @readerNextVolumeSemantic.
  ///
  /// In zh, this message translates to:
  /// **'系列下一卷'**
  String get readerNextVolumeSemantic;

  /// No description provided for @readerLastPage.
  ///
  /// In zh, this message translates to:
  /// **'尾页'**
  String get readerLastPage;

  /// No description provided for @readerLastPageSemantic.
  ///
  /// In zh, this message translates to:
  /// **'跳转到尾页'**
  String get readerLastPageSemantic;

  /// No description provided for @readerPrevPage.
  ///
  /// In zh, this message translates to:
  /// **'上一页'**
  String get readerPrevPage;

  /// No description provided for @readerNextPage.
  ///
  /// In zh, this message translates to:
  /// **'下一页'**
  String get readerNextPage;

  /// No description provided for @readerDisableAutoPlay.
  ///
  /// In zh, this message translates to:
  /// **'关闭自动播放'**
  String get readerDisableAutoPlay;

  /// No description provided for @readerEnableAutoPlay.
  ///
  /// In zh, this message translates to:
  /// **'开启自动播放'**
  String get readerEnableAutoPlay;

  /// No description provided for @readerInvalidParams.
  ///
  /// In zh, this message translates to:
  /// **'阅读参数错误：缺少 comic_id'**
  String get readerInvalidParams;

  /// No description provided for @readerSeriesAdvancePrompt.
  ///
  /// In zh, this message translates to:
  /// **'再次翻页将进入下一卷'**
  String get readerSeriesAdvancePrompt;

  /// No description provided for @readerNoImages.
  ///
  /// In zh, this message translates to:
  /// **'暂无图片'**
  String get readerNoImages;

  /// No description provided for @metadataTabAuthors.
  ///
  /// In zh, this message translates to:
  /// **'作者'**
  String get metadataTabAuthors;

  /// No description provided for @metadataTabTags.
  ///
  /// In zh, this message translates to:
  /// **'标签'**
  String get metadataTabTags;

  /// No description provided for @metadataAddAuthor.
  ///
  /// In zh, this message translates to:
  /// **'添加作者'**
  String get metadataAddAuthor;

  /// No description provided for @metadataAddTag.
  ///
  /// In zh, this message translates to:
  /// **'添加标签'**
  String get metadataAddTag;

  /// No description provided for @metadataAdd.
  ///
  /// In zh, this message translates to:
  /// **'添加'**
  String get metadataAdd;

  /// No description provided for @metadataSearchAuthorsHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索作者名称…'**
  String get metadataSearchAuthorsHint;

  /// No description provided for @metadataSearchTagsHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索标签名称…'**
  String get metadataSearchTagsHint;

  /// No description provided for @metadataRename.
  ///
  /// In zh, this message translates to:
  /// **'重命名'**
  String get metadataRename;

  /// No description provided for @metadataDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get metadataDelete;

  /// No description provided for @metadataMoreActions.
  ///
  /// In zh, this message translates to:
  /// **'更多操作'**
  String get metadataMoreActions;

  /// No description provided for @metadataAllAuthors.
  ///
  /// In zh, this message translates to:
  /// **'全部作者'**
  String get metadataAllAuthors;

  /// No description provided for @metadataAllTags.
  ///
  /// In zh, this message translates to:
  /// **'全部标签'**
  String get metadataAllTags;

  /// No description provided for @metadataTotalCount.
  ///
  /// In zh, this message translates to:
  /// **'{count, plural, other{共 {count} 条}}'**
  String metadataTotalCount(int count);

  /// No description provided for @metadataSelectedCount.
  ///
  /// In zh, this message translates to:
  /// **'已选 {count}'**
  String metadataSelectedCount(int count);

  /// No description provided for @metadataSelect.
  ///
  /// In zh, this message translates to:
  /// **'选中'**
  String get metadataSelect;

  /// No description provided for @metadataDeselect.
  ///
  /// In zh, this message translates to:
  /// **'取消选中'**
  String get metadataDeselect;

  /// No description provided for @metadataRenameAuthor.
  ///
  /// In zh, this message translates to:
  /// **'重命名作者'**
  String get metadataRenameAuthor;

  /// No description provided for @metadataRenameTag.
  ///
  /// In zh, this message translates to:
  /// **'重命名标签'**
  String get metadataRenameTag;

  /// No description provided for @metadataNewName.
  ///
  /// In zh, this message translates to:
  /// **'新名称'**
  String get metadataNewName;

  /// No description provided for @metadataRenameAuthorHint.
  ///
  /// In zh, this message translates to:
  /// **'输入新的作者名称…'**
  String get metadataRenameAuthorHint;

  /// No description provided for @metadataRenameTagHint.
  ///
  /// In zh, this message translates to:
  /// **'输入新的标签名称…'**
  String get metadataRenameTagHint;

  /// No description provided for @metadataNameLabel.
  ///
  /// In zh, this message translates to:
  /// **'名称'**
  String get metadataNameLabel;

  /// No description provided for @metadataAddAuthorHint.
  ///
  /// In zh, this message translates to:
  /// **'输入作者名称…'**
  String get metadataAddAuthorHint;

  /// No description provided for @metadataAddTagHint.
  ///
  /// In zh, this message translates to:
  /// **'输入标签名称…'**
  String get metadataAddTagHint;

  /// No description provided for @metadataAuthorDeletedToast.
  ///
  /// In zh, this message translates to:
  /// **'已删除作者'**
  String get metadataAuthorDeletedToast;

  /// No description provided for @metadataTagDeletedToast.
  ///
  /// In zh, this message translates to:
  /// **'已删除标签'**
  String get metadataTagDeletedToast;

  /// No description provided for @metadataAuthorsEmptyTitle.
  ///
  /// In zh, this message translates to:
  /// **'暂无作者'**
  String get metadataAuthorsEmptyTitle;

  /// No description provided for @metadataAuthorsEmptyHint.
  ///
  /// In zh, this message translates to:
  /// **'你可以从这里添加、重命名或删除作者。'**
  String get metadataAuthorsEmptyHint;

  /// No description provided for @metadataTagsEmptyTitle.
  ///
  /// In zh, this message translates to:
  /// **'暂无标签'**
  String get metadataTagsEmptyTitle;

  /// No description provided for @metadataTagsEmptyHint.
  ///
  /// In zh, this message translates to:
  /// **'你可以从这里添加、重命名或删除标签。'**
  String get metadataTagsEmptyHint;

  /// No description provided for @commonCancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get commonSave;

  /// No description provided for @commonSaveChanges.
  ///
  /// In zh, this message translates to:
  /// **'保存更改'**
  String get commonSaveChanges;

  /// No description provided for @commonClose.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get commonClose;

  /// No description provided for @commonConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认'**
  String get commonConfirm;

  /// No description provided for @commonDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get commonDelete;

  /// No description provided for @commonRemove.
  ///
  /// In zh, this message translates to:
  /// **'移除'**
  String get commonRemove;

  /// No description provided for @commonClear.
  ///
  /// In zh, this message translates to:
  /// **'清空'**
  String get commonClear;

  /// No description provided for @commonRetry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get commonRetry;

  /// No description provided for @commonOk.
  ///
  /// In zh, this message translates to:
  /// **'确定'**
  String get commonOk;

  /// No description provided for @commonLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载失败'**
  String get commonLoadFailed;

  /// No description provided for @commonBack.
  ///
  /// In zh, this message translates to:
  /// **'返回'**
  String get commonBack;

  /// No description provided for @commonSavedToast.
  ///
  /// In zh, this message translates to:
  /// **'已保存'**
  String get commonSavedToast;

  /// No description provided for @dialogEditSeriesTitle.
  ///
  /// In zh, this message translates to:
  /// **'编辑系列'**
  String get dialogEditSeriesTitle;

  /// No description provided for @dialogEditSeriesSavedToast.
  ///
  /// In zh, this message translates to:
  /// **'系列信息已保存'**
  String get dialogEditSeriesSavedToast;

  /// No description provided for @dialogEditMetadataTitle.
  ///
  /// In zh, this message translates to:
  /// **'编辑元数据'**
  String get dialogEditMetadataTitle;

  /// No description provided for @dialogEditMetadataTabGeneral.
  ///
  /// In zh, this message translates to:
  /// **'常规'**
  String get dialogEditMetadataTabGeneral;

  /// No description provided for @dialogEditMetadataTabAuthorsTags.
  ///
  /// In zh, this message translates to:
  /// **'作者&标签'**
  String get dialogEditMetadataTabAuthorsTags;

  /// No description provided for @formSeriesNameLabel.
  ///
  /// In zh, this message translates to:
  /// **'系列名称'**
  String get formSeriesNameLabel;

  /// No description provided for @formSeriesSerializationStatusLabel.
  ///
  /// In zh, this message translates to:
  /// **'连载状态'**
  String get formSeriesSerializationStatusLabel;

  /// No description provided for @formSeriesTotalCountLabel.
  ///
  /// In zh, this message translates to:
  /// **'漫画总数'**
  String get formSeriesTotalCountLabel;

  /// No description provided for @formSeriesTotalCountHint.
  ///
  /// In zh, this message translates to:
  /// **'留空表示不设置'**
  String get formSeriesTotalCountHint;

  /// No description provided for @formComicTitleLabel.
  ///
  /// In zh, this message translates to:
  /// **'漫画标题'**
  String get formComicTitleLabel;

  /// No description provided for @formComicTitleHint.
  ///
  /// In zh, this message translates to:
  /// **'修改漫画标题'**
  String get formComicTitleHint;

  /// No description provided for @formComicDescriptionLabel.
  ///
  /// In zh, this message translates to:
  /// **'概要'**
  String get formComicDescriptionLabel;

  /// No description provided for @formComicDescriptionHint.
  ///
  /// In zh, this message translates to:
  /// **'添加漫画简介…'**
  String get formComicDescriptionHint;

  /// No description provided for @formPublishedDateLabel.
  ///
  /// In zh, this message translates to:
  /// **'发布日期'**
  String get formPublishedDateLabel;

  /// No description provided for @formAgeRestrictionLabel.
  ///
  /// In zh, this message translates to:
  /// **'年龄限制'**
  String get formAgeRestrictionLabel;

  /// No description provided for @formDatePickerHint.
  ///
  /// In zh, this message translates to:
  /// **'选择发布日期'**
  String get formDatePickerHint;

  /// No description provided for @formDatePickerHelp.
  ///
  /// In zh, this message translates to:
  /// **'选择发布日期'**
  String get formDatePickerHelp;

  /// No description provided for @formDateFieldLabel.
  ///
  /// In zh, this message translates to:
  /// **'日期'**
  String get formDateFieldLabel;

  /// No description provided for @formDateFieldHint.
  ///
  /// In zh, this message translates to:
  /// **'年/月/日'**
  String get formDateFieldHint;

  /// No description provided for @formDateInvalidFormat.
  ///
  /// In zh, this message translates to:
  /// **'日期格式无效'**
  String get formDateInvalidFormat;

  /// No description provided for @formDateOutOfRange.
  ///
  /// In zh, this message translates to:
  /// **'日期超出可选范围'**
  String get formDateOutOfRange;

  /// No description provided for @formDateClearTooltip.
  ///
  /// In zh, this message translates to:
  /// **'清空日期'**
  String get formDateClearTooltip;

  /// No description provided for @formAuthorSelectPlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'选择或输入作者…'**
  String get formAuthorSelectPlaceholder;

  /// No description provided for @formAuthorListLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'作者列表加载失败'**
  String get formAuthorListLoadFailed;

  /// No description provided for @formAuthorEmptyCatalog.
  ///
  /// In zh, this message translates to:
  /// **'暂无作者'**
  String get formAuthorEmptyCatalog;

  /// No description provided for @formAuthorEmptyRemaining.
  ///
  /// In zh, this message translates to:
  /// **'没有更多可选'**
  String get formAuthorEmptyRemaining;

  /// No description provided for @formTagSelectPlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'选择或输入标签…'**
  String get formTagSelectPlaceholder;

  /// No description provided for @formTagListLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'标签列表加载失败'**
  String get formTagListLoadFailed;

  /// No description provided for @formTagEmptyCatalog.
  ///
  /// In zh, this message translates to:
  /// **'暂无标签'**
  String get formTagEmptyCatalog;

  /// No description provided for @formTagEmptyRemaining.
  ///
  /// In zh, this message translates to:
  /// **'没有更多可选'**
  String get formTagEmptyRemaining;

  /// No description provided for @scanDialogTitle.
  ///
  /// In zh, this message translates to:
  /// **'扫描漫画库'**
  String get scanDialogTitle;

  /// No description provided for @scanBackgroundAction.
  ///
  /// In zh, this message translates to:
  /// **'后台扫描'**
  String get scanBackgroundAction;

  /// No description provided for @scanPreparing.
  ///
  /// In zh, this message translates to:
  /// **'准备中…'**
  String get scanPreparing;

  /// No description provided for @scanGeneratingThumbnails.
  ///
  /// In zh, this message translates to:
  /// **'正在生成缩略图…'**
  String get scanGeneratingThumbnails;

  /// No description provided for @scanProgressSimple.
  ///
  /// In zh, this message translates to:
  /// **'{done} / {total}'**
  String scanProgressSimple(int done, int total);

  /// No description provided for @scanProgressWithFailed.
  ///
  /// In zh, this message translates to:
  /// **'{done} / {total} · 失败 {failed}'**
  String scanProgressWithFailed(int done, int total, int failed);

  /// No description provided for @scanSyncing.
  ///
  /// In zh, this message translates to:
  /// **'同步中…'**
  String get scanSyncing;

  /// No description provided for @scanWritingDb.
  ///
  /// In zh, this message translates to:
  /// **'正在写入数据库…'**
  String get scanWritingDb;

  /// No description provided for @scanClearingLibrary.
  ///
  /// In zh, this message translates to:
  /// **'正在清空漫画库…'**
  String get scanClearingLibrary;

  /// No description provided for @scanScanningFiles.
  ///
  /// In zh, this message translates to:
  /// **'正在扫描文件…'**
  String get scanScanningFiles;

  /// No description provided for @scanComplete.
  ///
  /// In zh, this message translates to:
  /// **'同步完成'**
  String get scanComplete;

  /// No description provided for @scanFailed.
  ///
  /// In zh, this message translates to:
  /// **'同步失败'**
  String get scanFailed;

  /// No description provided for @scanCancelled.
  ///
  /// In zh, this message translates to:
  /// **'已取消扫描'**
  String get scanCancelled;

  /// No description provided for @scanBackgroundThumbnails.
  ///
  /// In zh, this message translates to:
  /// **'后台生成缩略图 {done} / {total}{failedSuffix}'**
  String scanBackgroundThumbnails(int done, int total, String failedSuffix);

  /// No description provided for @scanThumbnailFailedSuffix.
  ///
  /// In zh, this message translates to:
  /// **' · 缩略图失败 {count}'**
  String scanThumbnailFailedSuffix(int count);

  /// No description provided for @scanDoneNoRoots.
  ///
  /// In zh, this message translates to:
  /// **'未配置有效路径，库中无漫画，同步已完成。'**
  String get scanDoneNoRoots;

  /// No description provided for @scanDoneCleared.
  ///
  /// In zh, this message translates to:
  /// **'已清空现有漫画数据。'**
  String get scanDoneCleared;

  /// No description provided for @scanDoneStats.
  ///
  /// In zh, this message translates to:
  /// **'同步完成 · 移除 {removed} · 新增 {added} · 保留 {kept}{thumbSuffix}'**
  String scanDoneStats(int removed, int added, int kept, String thumbSuffix);

  /// No description provided for @updateNewVersionTitle.
  ///
  /// In zh, this message translates to:
  /// **'发现新版本 v{version}'**
  String updateNewVersionTitle(String version);

  /// No description provided for @updatePublishedOn.
  ///
  /// In zh, this message translates to:
  /// **'发布于 {date}'**
  String updatePublishedOn(String date);

  /// No description provided for @updateRemindLater.
  ///
  /// In zh, this message translates to:
  /// **'稍后提醒'**
  String get updateRemindLater;

  /// No description provided for @updateViewDetails.
  ///
  /// In zh, this message translates to:
  /// **'查看详情'**
  String get updateViewDetails;

  /// No description provided for @updateNow.
  ///
  /// In zh, this message translates to:
  /// **'立即更新'**
  String get updateNow;

  /// No description provided for @updateManualDownloadToast.
  ///
  /// In zh, this message translates to:
  /// **'请手动下载适合您系统的安装包'**
  String get updateManualDownloadToast;

  /// No description provided for @updateDownloadingTitle.
  ///
  /// In zh, this message translates to:
  /// **'正在下载更新'**
  String get updateDownloadingTitle;

  /// No description provided for @updateDownloadFailed.
  ///
  /// In zh, this message translates to:
  /// **'下载失败，请重试'**
  String get updateDownloadFailed;

  /// No description provided for @confirmDeleteTagsTitle.
  ///
  /// In zh, this message translates to:
  /// **'确认删除'**
  String get confirmDeleteTagsTitle;

  /// No description provided for @confirmDeleteTagsContent.
  ///
  /// In zh, this message translates to:
  /// **'{count, plural, other{将删除 {count} 个标签，并同时从所有漫画中移除这些标签。此操作不可撤销。}}'**
  String confirmDeleteTagsContent(int count);

  /// No description provided for @confirmRemovePathTitle.
  ///
  /// In zh, this message translates to:
  /// **'确认移除'**
  String get confirmRemovePathTitle;

  /// No description provided for @confirmRemovePathContent.
  ///
  /// In zh, this message translates to:
  /// **'将从库中移除该路径。此操作不可撤销。'**
  String get confirmRemovePathContent;

  /// No description provided for @confirmClearHistoryTitle.
  ///
  /// In zh, this message translates to:
  /// **'确认清空'**
  String get confirmClearHistoryTitle;

  /// No description provided for @confirmClearHistoryContent.
  ///
  /// In zh, this message translates to:
  /// **'将清空全部阅读历史记录。此操作不可撤销。'**
  String get confirmClearHistoryContent;

  /// No description provided for @contextMenuGoToDetail.
  ///
  /// In zh, this message translates to:
  /// **'跳转到详情页'**
  String get contextMenuGoToDetail;

  /// No description provided for @breadcrumbReturnLibrary.
  ///
  /// In zh, this message translates to:
  /// **'返回漫画库'**
  String get breadcrumbReturnLibrary;

  /// No description provided for @breadcrumbReturnLibraryWithTrail.
  ///
  /// In zh, this message translates to:
  /// **'返回漫画库，当前：{trail}'**
  String breadcrumbReturnLibraryWithTrail(String trail);

  /// No description provided for @diagnosticModeBannerMessage.
  ///
  /// In zh, this message translates to:
  /// **'诊断模式已开启 · 正在记录更详细日志'**
  String get diagnosticModeBannerMessage;

  /// No description provided for @diagnosticModeDisable.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get diagnosticModeDisable;

  /// No description provided for @sidebarCollapse.
  ///
  /// In zh, this message translates to:
  /// **'收起侧边栏'**
  String get sidebarCollapse;

  /// No description provided for @sidebarExpand.
  ///
  /// In zh, this message translates to:
  /// **'展开侧边栏'**
  String get sidebarExpand;

  /// No description provided for @filterAdvancedTitle.
  ///
  /// In zh, this message translates to:
  /// **'高级筛选'**
  String get filterAdvancedTitle;

  /// No description provided for @filterResultCount.
  ///
  /// In zh, this message translates to:
  /// **'{count, plural, other{{count} 个结果}}'**
  String filterResultCount(int count);

  /// No description provided for @sortAndViewTitle.
  ///
  /// In zh, this message translates to:
  /// **'排序与视图'**
  String get sortAndViewTitle;

  /// No description provided for @contentRatingUnknown.
  ///
  /// In zh, this message translates to:
  /// **'未知'**
  String get contentRatingUnknown;

  /// No description provided for @contentRatingSafe.
  ///
  /// In zh, this message translates to:
  /// **'全年龄'**
  String get contentRatingSafe;

  /// No description provided for @contentRatingR18.
  ///
  /// In zh, this message translates to:
  /// **'NSFW'**
  String get contentRatingR18;

  /// No description provided for @relativeTimeJustNow.
  ///
  /// In zh, this message translates to:
  /// **'刚刚'**
  String get relativeTimeJustNow;

  /// No description provided for @relativeTimeMinutesAgo.
  ///
  /// In zh, this message translates to:
  /// **'{count, plural, other{{count} 分钟前}}'**
  String relativeTimeMinutesAgo(int count);

  /// No description provided for @relativeTimeHoursAgo.
  ///
  /// In zh, this message translates to:
  /// **'{count, plural, other{{count} 小时前}}'**
  String relativeTimeHoursAgo(int count);

  /// No description provided for @relativeTimeDaysAgo.
  ///
  /// In zh, this message translates to:
  /// **'{count, plural, other{{count} 天前}}'**
  String relativeTimeDaysAgo(int count);

  /// No description provided for @readingProgressPage.
  ///
  /// In zh, this message translates to:
  /// **'第 {page} 页'**
  String readingProgressPage(int page);

  /// No description provided for @historyDeleteRecord.
  ///
  /// In zh, this message translates to:
  /// **'删除记录'**
  String get historyDeleteRecord;

  /// No description provided for @bootstrapStartupFailed.
  ///
  /// In zh, this message translates to:
  /// **'启动失败：{error}'**
  String bootstrapStartupFailed(String error);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
