part of 'md3e_widgetbook_directories.dart';

/// Widgetbook：委托 Lab 目录 → 详情导航（按 index）。
void md3eWidgetbookOpenLabCatalogDetail(
  BuildContext context, {
  required LibraryDisplayTarget displayTarget,
  required int catalogIndex,
}) {
  openMd3eLabCatalogDetail(
    context,
    displayTarget: displayTarget,
    catalogIndex: catalogIndex,
  );
}

void md3eWidgetbookPushLabComicDetail(
  BuildContext context, {
  int catalogIndex = 0,
}) {
  openMd3eLabCatalogDetail(
    context,
    displayTarget: LibraryDisplayTarget.comics,
    catalogIndex: catalogIndex,
  );
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
