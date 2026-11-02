import 'package:flutter/material.dart';
import 'package:hentai_library/features/library_browse/presentation/views/comic_detail_md3e/comic_detail_page.dart';
import 'package:hentai_library/features/library_browse/presentation/views/series_detail_md3e/series_detail_page_entry.dart';
import 'package:hentai_library/features/library_browse/presentation/views/series_detail_md3e/series_detail_page_lab_host.dart';
import 'package:hentai_library/shared/ui/motion/shared_axis_route.dart';

import 'md3e_lab_catalog_detail_preview_data.dart';

import 'package:hentai_library/features/library_browse/presentation/patterns/metadata_edit/comic_metadata_edit_draft.dart';
import 'package:hentai_library/features/library_browse/presentation/patterns/metadata_edit/metadata_edit_navigation.dart';
import 'package:hentai_library/features/library_browse/presentation/patterns/metadata_edit/series_metadata_edit_draft.dart';

import 'md3e_lab_reader_navigation.dart';

import 'package:hentai_library/shared/ui/widgets/sheets/overlay_route_scope.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Lab 详情页头「更多」占位（不接生产 overflow 动作）。
const List<M3EMenuNode> kMd3eLabComicDetailMoreMenuEntries = <M3EMenuNode>[
  M3EMenuEntry(label: 'Lab · 分享'),
];

/// Lab：目录条目 → 详情（preview 数据；[rootNavigator: false]）。
Future<void> openMd3eLabCatalogDetail(
  BuildContext context, {
  required LibraryDisplayTarget displayTarget,
  required int catalogIndex,
}) {
  final Md3eOverlayRouteScopeSnapshot scope =
      Md3eOverlayRouteScopeSnapshot.capture(context);
  return Navigator.of(context, rootNavigator: false).push<void>(
    md3eSharedAxisRoute<void>(
      context,
      builder: (BuildContext routeContext) {
        return md3eOverlayRouteScope(
          scope: scope,
          child: switch (displayTarget) {
            LibraryDisplayTarget.comics => _Md3eLabComicDetailRoute(
              catalogIndex: catalogIndex,
            ),
            LibraryDisplayTarget.series => _Md3eLabSeriesDetailRoute(
              catalogIndex: catalogIndex,
            ),
          },
        );
      },
    ),
  );
}

class _Md3eLabComicDetailRoute extends StatelessWidget {
  const _Md3eLabComicDetailRoute({required this.catalogIndex});

  final int catalogIndex;

  @override
  Widget build(BuildContext context) {
    final Md3eComicDetailEntry entry =
        Md3eLabCatalogDetailPreviewData.comicDetail(catalogIndex: catalogIndex);
    return Md3eComicDetailPage(
      entry: entry,
      onBack: () => Navigator.of(context).maybePop(),
      moreMenuEntries: kMd3eLabComicDetailMoreMenuEntries,
      onRead: () {
        openMd3eLabReader(
          context,
          preview: md3eReaderPreviewDataForComicDetail(entry),
        );
      },
      onReadIncognito: () {
        openMd3eLabReader(
          context,
          preview: md3eReaderPreviewDataForComicDetail(entry),
        );
      },
      onEdit: () {
        showMd3eComicMetadataEdit(
          context: context,
          initialDraft: Md3eComicMetadataEditDraft.fromEntry(entry),
        );
      },
    );
  }
}

class _Md3eLabSeriesDetailRoute extends StatelessWidget {
  const _Md3eLabSeriesDetailRoute({required this.catalogIndex});

  final int catalogIndex;

  @override
  Widget build(BuildContext context) {
    final Md3eSeriesDetailEntry entry =
        Md3eLabCatalogDetailPreviewData.seriesDetail(
          catalogIndex: catalogIndex,
        );
    return Md3eSeriesDetailPageLabHost(
      entry: entry,
      onBack: () => Navigator.of(context).maybePop(),
      onEdit: () {
        showMd3eSeriesMetadataEdit(
          context: context,
          initialDraft: Md3eSeriesMetadataEditDraft.fromEntry(entry),
        );
      },
      onComicTap: (int comicIndex) {
        final Md3eComicDetailEntry comicEntry =
            Md3eLabCatalogDetailPreviewData.comicDetailFromSeriesVolume(
              series: entry,
              comicIndex: comicIndex,
            );
        final Md3eOverlayRouteScopeSnapshot scope =
            Md3eOverlayRouteScopeSnapshot.capture(context);
        Navigator.of(context, rootNavigator: false).push<void>(
          md3eSharedAxisRoute<void>(
            context,
            builder: (BuildContext routeContext) {
              return md3eOverlayRouteScope(
                scope: scope,
                child: Md3eComicDetailPage(
                  entry: comicEntry,
                  onBack: () => Navigator.of(routeContext).maybePop(),
                  moreMenuEntries: kMd3eLabComicDetailMoreMenuEntries,
                  onRead: () {
                    openMd3eLabReader(
                      routeContext,
                      preview: md3eReaderPreviewDataForComicDetail(comicEntry),
                    );
                  },
                  onReadIncognito: () {
                    openMd3eLabReader(
                      routeContext,
                      preview: md3eReaderPreviewDataForComicDetail(comicEntry),
                    );
                  },
                  onEdit: () {
                    showMd3eComicMetadataEdit(
                      context: routeContext,
                      initialDraft: Md3eComicMetadataEditDraft.fromEntry(
                        comicEntry,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}
