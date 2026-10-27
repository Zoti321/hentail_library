part of 'md3e_widgetbook_directories.dart';

/// Widgetbook Lab：目录卡片 → 固定示例详情（不区分具体条目）。
void md3eWidgetbookOpenLabCatalogDetail(
  BuildContext context, {
  required LibraryDisplayTarget displayTarget,
}) {
  Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (BuildContext routeContext) => switch (displayTarget) {
        LibraryDisplayTarget.comics =>
          _md3eWidgetbookLabComicDetailPage(routeContext),
        LibraryDisplayTarget.series =>
          _md3eWidgetbookLabSeriesDetailPage(routeContext),
      },
    ),
  );
}

void md3eWidgetbookPushLabComicDetail(BuildContext context) {
  Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (BuildContext routeContext) =>
          _md3eWidgetbookLabComicDetailPage(routeContext),
    ),
  );
}

Widget _md3eWidgetbookLabComicDetailPage(BuildContext context) {
  final Md3eComicDetailEntry entry = Md3eComicDetailPagePreviewData.sample();
  return Md3eComicDetailPage(
    entry: entry,
    onBack: () => _md3eWidgetbookPopLabRoute(context),
    onEdit: () => _md3eWidgetbookOpenLabComicMetadataEdit(context, entry: entry),
  );
}

Widget _md3eWidgetbookLabSeriesDetailPage(BuildContext context) {
  final Md3eSeriesDetailEntry entry = Md3eSeriesDetailPagePreviewData.sample();
  return Md3eSeriesDetailPage(
    entry: entry,
    onBack: () => _md3eWidgetbookPopLabRoute(context),
    onEdit: () => _md3eWidgetbookOpenLabSeriesMetadataEdit(context, entry: entry),
    onComicTap: (_) => md3eWidgetbookPushLabComicDetail(context),
  );
}

void _md3eWidgetbookPopLabRoute(BuildContext context) {
  if (!context.mounted) {
    return;
  }
  Navigator.of(context).pop();
}

void _md3eWidgetbookOpenLabComicMetadataEdit(
  BuildContext context, {
  required Md3eComicDetailEntry entry,
}) {
  showMd3eComicMetadataEdit(
    context: context,
    initialDraft: Md3eComicMetadataEditDraft.fromEntry(entry),
  );
}

void _md3eWidgetbookOpenLabSeriesMetadataEdit(
  BuildContext context, {
  required Md3eSeriesDetailEntry entry,
}) {
  showMd3eSeriesMetadataEdit(
    context: context,
    initialDraft: Md3eSeriesMetadataEditDraft.fromEntry(entry),
  );
}
