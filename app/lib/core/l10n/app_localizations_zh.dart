// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get libraryTitle => '漫画库';

  @override
  String get libraryEmptyTitle => '暂无漫画';

  @override
  String get libraryEmptyHint => '请先在「选中路径」中添加路径并扫描';

  @override
  String get librarySeriesEmptyTitle => '暂无系列';

  @override
  String get librarySeriesEmptyHint => '系列由扫描结果自动生成，添加路径并扫描后即可出现';

  @override
  String get libraryNoMatchTitle => '没有匹配结果';

  @override
  String get libraryNoMatchFilterHintComics => '当前筛选条件下没有漫画';

  @override
  String get libraryNoMatchFilterHintSeries => '当前筛选条件下没有系列';

  @override
  String comicCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 本',
      zero: '0 本',
    );
    return '$_temp0';
  }

  @override
  String get settingsLanguageLabel => '界面语言';

  @override
  String get localePreferenceSystem => '跟随系统';

  @override
  String get localePreferenceZhCn => '中文';

  @override
  String get localePreferenceEn => 'English';

  @override
  String get settingsThemeLabel => '应用主题';

  @override
  String get themePreferenceSystem => '跟随系统';

  @override
  String get themePreferenceLight => '浅色';

  @override
  String get themePreferenceDark => '深色';

  @override
  String get navHome => '首页';

  @override
  String get navMetadata => '管理';

  @override
  String get navHistory => '历史';

  @override
  String get navSettings => '设置';

  @override
  String get pageTitleReader => '阅读';

  @override
  String get pageTitleComicDetail => '漫画详情';

  @override
  String get pageTitleSeriesDetail => '系列详情';

  @override
  String get pageTitlePaths => '库路径';

  @override
  String get pageTitleSearchResults => '搜索结果';

  @override
  String get pageTitleNotFound => '页面不存在';

  @override
  String get shellOpenNavMenu => '打开导航菜单';

  @override
  String get shellLoadFailed => '加载失败';

  @override
  String get shellLoading => '加载中…';

  @override
  String get shellBack => '返回';

  @override
  String get shellBackToSettings => '返回设置';

  @override
  String get shellRetry => '重试';

  @override
  String get shellRetrying => '重试中…';

  @override
  String get shellProcessing => '处理中…';

  @override
  String get homeTitle => '首页';

  @override
  String get homeScanLibrary => '扫描漫画库';

  @override
  String get homeGreetingLateNight => '凌晨好';

  @override
  String get homeGreetingEarlyMorning => '早上好';

  @override
  String get homeGreetingMorning => '上午好';

  @override
  String get homeGreetingNoon => '中午好';

  @override
  String get homeGreetingAfternoon => '下午好';

  @override
  String get homeGreetingEvening => '晚上好';

  @override
  String get homeGreetingLate => '夜深了';

  @override
  String homeGreetingReader(String greeting) {
    return '$greeting，读者';
  }

  @override
  String get homeEmptyTitle => '尚未导入漫画';

  @override
  String get homeEmptyHint => '请先在设置中添加库文件夹并扫描；若已配置，可检查选中路径或重新扫描。';

  @override
  String get pathsTitle => '选中路径';

  @override
  String get homeStatSeries => '系列';

  @override
  String get homeStatTags => '标签';

  @override
  String get homeStatAuthors => '作者';

  @override
  String homeComicTotal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 本',
    );
    return '共 $_temp0';
  }

  @override
  String homeSeriesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个系列',
    );
    return '$_temp0';
  }

  @override
  String homeTagCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个标签',
    );
    return '$_temp0';
  }

  @override
  String homeAuthorCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 位',
    );
    return '$_temp0';
  }

  @override
  String get homeNoAuthors => '暂无作者';

  @override
  String get homeContinueReading => '继续阅读';

  @override
  String get homeNoReadingHistory => '暂无阅读记录，';

  @override
  String get homeGoToLibrary => '去漫画库';

  @override
  String get historyTitle => '阅读历史';

  @override
  String get historyClearAction => '清空阅读历史';

  @override
  String get historyClearedToast => '已清空阅读历史';

  @override
  String historyRecordSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 条记录 • 最长保留 30 天',
    );
    return '$_temp0';
  }

  @override
  String get historySearchHint => '搜索历史记录...';

  @override
  String get historyEmpty => '暂无阅读历史';

  @override
  String get historyNoMatch => '没有匹配的历史记录';

  @override
  String get historyDeletedToast => '已删除记录';

  @override
  String get pathsSavedHeading => '已保存路径';

  @override
  String pathsTotalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '共 $count 项',
    );
    return '$_temp0';
  }

  @override
  String get pathsEmptyHint => '暂无路径，请添加文件夹';

  @override
  String get pathsAddButton => '添加路径';

  @override
  String get pathsAddedOneToast => '已添加 1 个路径';

  @override
  String get pathsRemovedToast => '已移除路径';

  @override
  String get pathsRemoveAction => '移除路径';

  @override
  String get pathsLoadFailed => '路径加载失败';

  @override
  String get notFoundTitle => '页面不存在';

  @override
  String get notFoundHint => '你访问的链接可能已失效，或页面已被移除。';

  @override
  String get notFoundGoHome => '返回首页';

  @override
  String get notFoundGoLibrary => '去漫画库';

  @override
  String get settingsGroupPersonalization => '个性化';

  @override
  String get settingsGroupLibrary => '漫画库';

  @override
  String get settingsGroupDiagnostics => '诊断与支持';

  @override
  String get settingsGroupAbout => '关于';

  @override
  String get settingsDiagnosticModeLabel => '详细诊断';

  @override
  String get settingsDiagnosticModeDescriptionEnabled =>
      '已开启：Dart 与 Rust 记录更详细日志';

  @override
  String get settingsDiagnosticModeDescriptionDisabled => '临时提高日志详细程度，便于复现问题';

  @override
  String get settingsDiagnosticModeEnabledBadge => '已开启';

  @override
  String get settingsExportLogsLabel => '导出日志';

  @override
  String get settingsExportLogsDescription => '打包应用与核心日志，便于问题反馈';

  @override
  String get settingsLibraryLocationLabel => '库位置';

  @override
  String get settingsAutoScanLabel => '自动扫描';

  @override
  String get settingsAutoUpdateLabel => '自动更新';

  @override
  String settingsCurrentVersion(String version) {
    return '当前版本 v$version';
  }

  @override
  String get settingsCurrentVersionLoading => '当前版本 …';

  @override
  String get settingsCheckForUpdatesLabel => '检查更新';

  @override
  String get settingsUpdateCheckFailed => '检查更新失败，请稍后重试';

  @override
  String get settingsUpdateUpToDate => '当前已是最新版本';

  @override
  String get libraryTabComics => '漫画';

  @override
  String get libraryTabSeries => '系列';

  @override
  String librarySeriesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个系列',
    );
    return '$_temp0';
  }

  @override
  String get libraryManageScanPaths => '管理扫描路径';

  @override
  String get librarySearchHint => '搜索…';

  @override
  String get librarySearchKeywordEmpty => '关键词不能为空';

  @override
  String get libraryFilterSortTooltip => '筛选与排序';

  @override
  String get libraryFilterSortSemantic => '打开筛选与排序';

  @override
  String get libraryPageSizeTooltip => '每页数量';

  @override
  String get libraryPageSizeSemantic => '设置每页数量';

  @override
  String get libraryScanCancelledToast => '已取消扫描';

  @override
  String get libraryScanningDeep => '正在深度扫描…';

  @override
  String get libraryScanning => '正在扫描…';

  @override
  String get libraryCancelScan => '取消扫描';

  @override
  String get libraryMoreActions => '更多操作';

  @override
  String get libraryMoreActionsSemantic => '打开更多操作';

  @override
  String get libraryRefresh => '刷新';

  @override
  String get libraryScan => '扫描';

  @override
  String get libraryDeepScan => '深度扫描';

  @override
  String get libraryScrollToTop => '回到顶部';

  @override
  String get libraryFilterSection => '筛选';

  @override
  String get librarySortSection => '排序';

  @override
  String get libraryAgeRestrictionFilter => '年龄限制';

  @override
  String get libraryMediaTypeFilter => '媒体类型';

  @override
  String get libraryComingSoon => '即将推出';

  @override
  String get libraryComicSortTitle => '标题';

  @override
  String get libraryComicSortCreatedAt => '添加时间';

  @override
  String get libraryComicSortLastUpdatedAt => '更新时间';

  @override
  String get libraryComicSortPublishedAt => '发布日期';

  @override
  String get libraryComicSortReadAt => '阅读日期';

  @override
  String get libraryComicSortFileSize => '文件大小';

  @override
  String get libraryComicSortPageCount => '页数';

  @override
  String get librarySeriesSortName => '名称';

  @override
  String get librarySeriesSortComicCount => '漫画数量';

  @override
  String get librarySeriesSortRandom => '随机';

  @override
  String get filterAgeUnrestricted => '不限';

  @override
  String get filterAgeAllAges => '全年龄';

  @override
  String get filterAgeR18Only => 'R18';

  @override
  String get filterMediaTypePdf => 'PDF';

  @override
  String get filterMediaTypeEpub => 'EPUB';

  @override
  String get filterMediaTypeArchive => '压缩包';

  @override
  String get libraryScanComplete => '扫描完成';

  @override
  String get libraryDeepScanComplete => '深度扫描完成';

  @override
  String get libraryScanCompleteNoRoots => '扫描完成：未配置扫描路径';

  @override
  String get libraryDeepScanCompleteNoRoots => '深度扫描完成：未配置扫描路径';

  @override
  String libraryScanCompleteCleared(int count) {
    return '扫描完成：已移除 $count 项';
  }

  @override
  String libraryDeepScanCompleteCleared(int count) {
    return '深度扫描完成：已移除 $count 项';
  }

  @override
  String libraryScanCompleteStats(int added, int removed, int kept) {
    return '扫描完成：新增 $added，移除 $removed，保留 $kept';
  }

  @override
  String libraryDeepScanCompleteStats(int added, int removed, int kept) {
    return '深度扫描完成：新增 $added，移除 $removed，保留 $kept';
  }

  @override
  String get searchResultsTitle => '搜索结果';

  @override
  String searchResultsForQuery(String query) {
    return '\"$query\"的搜索结果';
  }

  @override
  String get searchEnterKeyword => '请输入关键词后按回车搜索';

  @override
  String searchLoadFailed(String error) {
    return '加载失败：$error';
  }

  @override
  String get searchBackToLibrary => '返回漫画库';

  @override
  String get searchScrollLeft => '向左滚动';

  @override
  String get searchScrollRight => '向右滚动';

  @override
  String comicDetailPageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 页',
    );
    return '$_temp0';
  }

  @override
  String get comicDetailAuthors => '作者';

  @override
  String get comicDetailTags => '标签';

  @override
  String get comicDetailResourceFormat => '资源格式';

  @override
  String get comicDetailResourceSize => '资源大小';

  @override
  String get comicDetailResourcePath => '资源路径';

  @override
  String get comicDetailAddedAt => '添加时间';

  @override
  String get comicDetailUpdatedAt => '更新时间';

  @override
  String get comicDetailRead => '阅读';

  @override
  String get comicDetailReadIncognito => '无痕阅读';

  @override
  String get comicDetailEditMetadata => '编辑元数据';

  @override
  String get comicDetailShowInExplorer => '在资源管理器中显示';

  @override
  String get comicDetailShowInExplorerFailed => '无法在文件资源管理器中显示该项目';

  @override
  String get comicDetailDelete => '删除';

  @override
  String get comicDetailDeleteTitle => '删除漫画？';

  @override
  String comicDetailDeleteConfirm(String title) {
    return '将删除「$title」。此操作不可撤销。';
  }

  @override
  String get comicDetailCancel => '取消';

  @override
  String get comicDetailDeletedToast => '已删除漫画';

  @override
  String get comicDetailNotFound => '漫画不存在或已移除';

  @override
  String get comicDetailLoadFailedRetry => '加载失败，请重试';

  @override
  String get comicDetailGoToLibrary => '前往漫画库';

  @override
  String get comicDetailSeriesNavConflict => '系列数据异常：该漫画同时属于多个系列，无法使用系列导航';

  @override
  String get comicDetailSeriesPrev => '上一本';

  @override
  String get comicDetailSeriesPrevSemantic => '系列上一本';

  @override
  String get comicDetailSeriesCatalog => '系列目录';

  @override
  String get comicDetailSeriesNext => '下一本';

  @override
  String get comicDetailSeriesNextSemantic => '系列下一本';

  @override
  String get seriesDetailEdit => '编辑系列';

  @override
  String get seriesDetailNoComics => '系列内暂无漫画';

  @override
  String get seriesDetailComicsLoadFailed => '漫画列表加载失败';

  @override
  String get seriesDetailUnknown => '未知系列';

  @override
  String seriesDetailNotFound(String name) {
    return '未找到系列「$name」';
  }

  @override
  String seriesDetailVolumeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 本',
    );
    return '$_temp0';
  }

  @override
  String seriesDetailVolumeProgress(int current, int total) {
    return '$current / 共 $total 本';
  }

  @override
  String seriesDetailPaginationPage(int page, int totalPages) {
    return '第 $page / $totalPages 页';
  }

  @override
  String get seriesDetailPaginationFirst => '首页';

  @override
  String get seriesDetailPaginationPrevious => '上一页';

  @override
  String get seriesDetailPaginationNext => '下一页';

  @override
  String get seriesDetailPaginationLast => '末页';

  @override
  String get serializationStatusOngoing => '连载中';

  @override
  String get serializationStatusEnded => '已完结';

  @override
  String get serializationStatusHiatus => '休刊';

  @override
  String get serializationStatusUnknown => '未知';

  @override
  String get readerSettingsTitle => '阅读设置';

  @override
  String get readerSettingsClose => '关闭';

  @override
  String get readerSettingsGeneral => '常规';

  @override
  String get readerSettingsReadingMode => '阅读模式';

  @override
  String get readerSettingsAutoPlay => '自动播放';

  @override
  String get readerSettingsPlayInterval => '播放间隔';

  @override
  String get readerSettingsSecondsSuffix => '秒';

  @override
  String get readerSettingsWebtoonMode => 'Webtoon 模式';

  @override
  String get readerSettingsPagedOptions => '分页阅读器选项';

  @override
  String get readerSettingsHorizontalMargin => '左右边距';

  @override
  String get readerSettingsMarginNone => '无 (0%)';

  @override
  String readerSettingsMarginPercent(int percent) {
    return '$percent%';
  }

  @override
  String get readerSettingsZoomMode => '缩放模式';

  @override
  String get readerSettingsPageLayout => '页面布局';

  @override
  String get readingModeCategoryPaged => '翻页';

  @override
  String get readingModeCategoryWebtoon => 'Webtoon';

  @override
  String get readingModePaged => '翻页';

  @override
  String get readingModeWebtoon => 'Webtoon';

  @override
  String get readingModeDualPage => '双页';

  @override
  String get readingModeDualPageNoCover => '双页（封面独立）';

  @override
  String get readingModePagedSingle => '单页';

  @override
  String get readingModePagedDual => '双页';

  @override
  String get readingModePagedDualNoCover => '双页（封面独立）';

  @override
  String get readingModeWebtoonFitWidth => '适应宽度';

  @override
  String get readingModeWebtoonOriginalSize => '原始尺寸';

  @override
  String get readerSetComicCover => '将当前页设为漫画封面';

  @override
  String get readerSetSeriesCover => '将当前页设为系列封面';

  @override
  String get readerMore => '更多';

  @override
  String get readerMoreSemantic => '更多阅读选项';

  @override
  String get readerStateNotReady => '阅读状态未就绪';

  @override
  String get readerComicCoverSet => '已设为漫画封面';

  @override
  String readerComicCoverSetFailed(String error) {
    return '设置漫画封面失败：$error';
  }

  @override
  String get readerSeriesCoverSet => '已设为系列封面';

  @override
  String readerSeriesCoverSetFailed(String error) {
    return '设置系列封面失败：$error';
  }

  @override
  String get readerBackSemantic => '返回上一页';

  @override
  String get readerExitFullscreen => '退出全屏';

  @override
  String get readerEnterFullscreen => '全屏';

  @override
  String get readerExitFullscreenSemantic => '退出全屏';

  @override
  String get readerEnterFullscreenSemantic => '进入全屏';

  @override
  String get readerOpenSettingsSemantic => '打开阅读设置';

  @override
  String get readerSeriesCatalog => '系列目录';

  @override
  String get readerPrevVolume => '上一卷';

  @override
  String get readerPrevVolumeSemantic => '系列上一卷';

  @override
  String get readerFirstPage => '首页';

  @override
  String get readerFirstPageSemantic => '跳转到首页';

  @override
  String get readerNextVolume => '下一卷';

  @override
  String get readerNextVolumeSemantic => '系列下一卷';

  @override
  String get readerLastPage => '尾页';

  @override
  String get readerLastPageSemantic => '跳转到尾页';

  @override
  String get readerPrevPage => '上一页';

  @override
  String get readerNextPage => '下一页';

  @override
  String get readerDisableAutoPlay => '关闭自动播放';

  @override
  String get readerEnableAutoPlay => '开启自动播放';

  @override
  String get readerInvalidParams => '阅读参数错误：缺少 comic_id';

  @override
  String get readerSeriesAdvancePrompt => '再次翻页将进入下一卷';

  @override
  String get readerNoImages => '暂无图片';

  @override
  String get metadataTabAuthors => '作者';

  @override
  String get metadataTabTags => '标签';

  @override
  String get metadataAddAuthor => '添加作者';

  @override
  String get metadataAddTag => '添加标签';

  @override
  String get metadataAdd => '添加';

  @override
  String get metadataSearchNameHint => '搜索名称…';

  @override
  String get metadataRename => '重命名';

  @override
  String get metadataDelete => '删除';

  @override
  String get metadataMoreActions => '更多操作';

  @override
  String get metadataAllAuthors => '全部作者';

  @override
  String get metadataAllTags => '全部标签';

  @override
  String metadataTotalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '共 $count 条',
    );
    return '$_temp0';
  }

  @override
  String get metadataRenameAuthor => '重命名作者';

  @override
  String get metadataRenameTag => '重命名标签';

  @override
  String get metadataNewName => '新名称';

  @override
  String get metadataRenameAuthorHint => '输入新的作者名称…';

  @override
  String get metadataRenameTagHint => '输入新的标签名称…';

  @override
  String get metadataNameLabel => '名称';

  @override
  String get metadataAddAuthorHint => '输入作者名称…';

  @override
  String get metadataAddTagHint => '输入标签名称…';

  @override
  String get metadataAuthorDeletedToast => '已删除作者';

  @override
  String get metadataTagDeletedToast => '已删除标签';

  @override
  String get metadataAuthorsEmptyTitle => '暂无作者';

  @override
  String get metadataAuthorsEmptyHint => '你可以从这里添加、重命名或删除作者。';

  @override
  String get metadataTagsEmptyTitle => '暂无标签';

  @override
  String get metadataTagsEmptyHint => '你可以从这里添加、重命名或删除标签。';

  @override
  String get metadataAuthorsNoMatchTitle => '未找到匹配的作者';

  @override
  String get metadataTagsNoMatchTitle => '未找到匹配的标签';

  @override
  String get metadataSearchNoMatchHint => '试试其他关键词，或清空搜索';

  @override
  String get commonCancel => '取消';

  @override
  String get commonSave => '保存';

  @override
  String get commonSaveChanges => '保存更改';

  @override
  String get commonClose => '关闭';

  @override
  String get commonConfirm => '确认';

  @override
  String get commonDelete => '删除';

  @override
  String get commonRemove => '移除';

  @override
  String get commonClear => '清空';

  @override
  String get commonRetry => '重试';

  @override
  String get commonOk => '确定';

  @override
  String get commonLoadFailed => '加载失败';

  @override
  String get commonBack => '返回';

  @override
  String get commonSavedToast => '已保存';

  @override
  String get dialogEditSeriesTitle => '编辑系列';

  @override
  String get dialogEditSeriesSavedToast => '系列信息已保存';

  @override
  String get dialogEditMetadataTitle => '编辑元数据';

  @override
  String get dialogEditMetadataTabGeneral => '常规';

  @override
  String get dialogEditMetadataTabAuthorsTags => '作者&标签';

  @override
  String get formSeriesNameLabel => '系列名称';

  @override
  String get formSeriesSerializationStatusLabel => '连载状态';

  @override
  String get formSeriesTotalCountLabel => '漫画总数';

  @override
  String get formSeriesTotalCountHint => '留空表示不设置';

  @override
  String get formComicTitleLabel => '漫画标题';

  @override
  String get formComicTitleHint => '修改漫画标题';

  @override
  String get formComicDescriptionLabel => '概要';

  @override
  String get formComicDescriptionHint => '添加漫画简介…';

  @override
  String get formPublishedDateLabel => '发布日期';

  @override
  String get formAgeRestrictionLabel => '年龄限制';

  @override
  String get formDatePickerHint => '选择发布日期';

  @override
  String get formDatePickerHelp => '选择发布日期';

  @override
  String get formDateFieldLabel => '日期';

  @override
  String get formDateFieldHint => '年/月/日';

  @override
  String get formDateInvalidFormat => '日期格式无效';

  @override
  String get formDateOutOfRange => '日期超出可选范围';

  @override
  String get formDateClearTooltip => '清空日期';

  @override
  String get formAuthorSelectPlaceholder => '选择或输入作者…';

  @override
  String get formAuthorListLoadFailed => '作者列表加载失败';

  @override
  String get formAuthorEmptyCatalog => '暂无作者';

  @override
  String get formAuthorEmptyRemaining => '没有更多可选';

  @override
  String get formTagSelectPlaceholder => '选择或输入标签…';

  @override
  String get formTagListLoadFailed => '标签列表加载失败';

  @override
  String get formTagEmptyCatalog => '暂无标签';

  @override
  String get formTagEmptyRemaining => '没有更多可选';

  @override
  String get scanDialogTitle => '扫描漫画库';

  @override
  String get scanBackgroundAction => '后台扫描';

  @override
  String get scanPreparing => '准备中…';

  @override
  String get scanGeneratingThumbnails => '正在生成缩略图…';

  @override
  String scanProgressSimple(int done, int total) {
    return '$done / $total';
  }

  @override
  String scanProgressWithFailed(int done, int total, int failed) {
    return '$done / $total · 失败 $failed';
  }

  @override
  String get scanSyncing => '同步中…';

  @override
  String get scanWritingDb => '正在写入数据库…';

  @override
  String get scanClearingLibrary => '正在清空漫画库…';

  @override
  String get scanScanningFiles => '正在扫描文件…';

  @override
  String get scanComplete => '同步完成';

  @override
  String get scanFailed => '同步失败';

  @override
  String get scanCancelled => '已取消扫描';

  @override
  String scanBackgroundThumbnails(int done, int total, String failedSuffix) {
    return '后台生成缩略图 $done / $total$failedSuffix';
  }

  @override
  String scanThumbnailFailedSuffix(int count) {
    return ' · 缩略图失败 $count';
  }

  @override
  String get scanDoneNoRoots => '未配置有效路径，库中无漫画，同步已完成。';

  @override
  String get scanDoneCleared => '已清空现有漫画数据。';

  @override
  String scanDoneStats(int removed, int added, int kept, String thumbSuffix) {
    return '同步完成 · 移除 $removed · 新增 $added · 保留 $kept$thumbSuffix';
  }

  @override
  String updateNewVersionTitle(String version) {
    return '发现新版本 v$version';
  }

  @override
  String updatePublishedOn(String date) {
    return '发布于 $date';
  }

  @override
  String get updateRemindLater => '稍后提醒';

  @override
  String get updateViewDetails => '查看详情';

  @override
  String get updateNow => '立即更新';

  @override
  String get updateManualDownloadToast => '请手动下载适合您系统的安装包';

  @override
  String get updateDownloadingTitle => '正在下载更新';

  @override
  String get updateDownloadFailed => '下载失败，请重试';

  @override
  String get confirmDeleteTagsTitle => '确认删除';

  @override
  String confirmDeleteTagsContent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '将删除 $count 个标签，并同时从所有漫画中移除这些标签。此操作不可撤销。',
    );
    return '$_temp0';
  }

  @override
  String get confirmRemovePathTitle => '确认移除';

  @override
  String get confirmRemovePathContent => '将从库中移除该路径。此操作不可撤销。';

  @override
  String get confirmClearHistoryTitle => '确认清空';

  @override
  String get confirmClearHistoryContent => '将清空全部阅读历史记录。此操作不可撤销。';

  @override
  String get contextMenuGoToDetail => '跳转到详情页';

  @override
  String get breadcrumbReturnLibrary => '返回漫画库';

  @override
  String breadcrumbReturnLibraryWithTrail(String trail) {
    return '返回漫画库，当前：$trail';
  }

  @override
  String get diagnosticModeBannerMessage => '诊断模式已开启 · 正在记录更详细日志';

  @override
  String get diagnosticModeDisable => '关闭';

  @override
  String get sidebarCollapse => '收起侧边栏';

  @override
  String get sidebarExpand => '展开侧边栏';

  @override
  String get filterAdvancedTitle => '高级筛选';

  @override
  String filterResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个结果',
    );
    return '$_temp0';
  }

  @override
  String get sortAndViewTitle => '排序与视图';

  @override
  String get contentRatingUnknown => '未知';

  @override
  String get contentRatingSafe => '全年龄';

  @override
  String get contentRatingR18 => 'NSFW';

  @override
  String get relativeTimeJustNow => '刚刚';

  @override
  String relativeTimeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 分钟前',
    );
    return '$_temp0';
  }

  @override
  String relativeTimeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 小时前',
    );
    return '$_temp0';
  }

  @override
  String relativeTimeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 天前',
    );
    return '$_temp0';
  }

  @override
  String readingProgressPage(int page) {
    return '第 $page 页';
  }

  @override
  String get historyDeleteRecord => '删除记录';

  @override
  String bootstrapStartupFailed(String error) {
    return '启动失败：$error';
  }
}
