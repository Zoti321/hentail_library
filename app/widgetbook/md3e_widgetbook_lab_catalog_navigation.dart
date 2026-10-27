part of 'md3e_widgetbook_directories.dart';

/// Widgetbook Lab：目录卡片 → 固定示例详情（不区分具体条目）。
void md3eWidgetbookOpenLabCatalogDetail(
  BuildContext context, {
  required LibraryDisplayTarget displayTarget,
}) {
  final Widget page = switch (displayTarget) {
    LibraryDisplayTarget.comics => Md3eComicDetailPage(
      entry: Md3eComicDetailPagePreviewData.sample(),
      onBack: () => Navigator.of(context).pop(),
    ),
    LibraryDisplayTarget.series => Md3eSeriesDetailPage(
      entry: Md3eSeriesDetailPagePreviewData.sample(),
      onBack: () => Navigator.of(context).pop(),
    ),
  };

  Navigator.of(context).push<void>(
    MaterialPageRoute<void>(builder: (BuildContext _) => page),
  );
}
