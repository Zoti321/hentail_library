part of 'md3e_widgetbook_directories.dart';

/// Widgetbook：委托 Lab 目录 → 详情导航（按 index）。
void md3eWidgetbookOpenLabCatalogDetail(
  BuildContext context, {
  required LibraryDisplayTarget displayTarget,
  required int catalogIndex,
}) {
  openLabCatalogDetail(
    context,
    displayTarget: displayTarget,
    catalogIndex: catalogIndex,
  );
}

void md3eWidgetbookPushLabComicDetail(
  BuildContext context, {
  int catalogIndex = 0,
}) {
  openLabCatalogDetail(
    context,
    displayTarget: LibraryDisplayTarget.comics,
    catalogIndex: catalogIndex,
  );
}

void _md3eWidgetbookOpenLabComicMetadataEdit(
  BuildContext context, {
  required ComicDetailViewObject entry,
}) {
  showComicMetadataEditLayout(
    context: context,
    initialDraft: ComicMetadataEditDraft.fromEntry(entry),
  );
}

void _md3eWidgetbookOpenLabSeriesMetadataEdit(
  BuildContext context, {
  required SeriesDetailViewObject entry,
}) {
  showSeriesMetadataEditLayout(
    context: context,
    initialDraft: SeriesMetadataEditDraft.fromEntry(entry),
  );
}
