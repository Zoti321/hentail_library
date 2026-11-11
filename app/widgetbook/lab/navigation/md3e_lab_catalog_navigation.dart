import 'package:flutter/material.dart';
import 'package:hentai_library/features/comic/presentation/views/comic_detail/comic_detail_page.dart';
import 'package:hentai_library/features/series/presentation/views/series_detail/series_detail_page_lab_host.dart';
import 'package:hentai_library/design-system/design_system.dart';

import '../data/md3e_lab_catalog_detail_preview_data.dart';

import 'package:hentai_library/features/comic/public/ui/comic_metadata_edit_draft.dart';
import 'package:hentai_library/features/comic/public/ui/comic_metadata_edit_layout.dart';
import 'package:hentai_library/features/comic/public/ui/comic_metadata_edit_present.dart';
import 'package:hentai_library/features/series/public/ui/series_metadata_edit_draft.dart';
import 'package:hentai_library/features/series/public/ui/series_metadata_edit_layout.dart';
import 'package:hentai_library/features/series/public/ui/series_metadata_edit_present.dart';

import 'md3e_lab_reader_navigation.dart';

import 'package:hentai_library/shared/ui/widgets/sheets/overlay_route_scope.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Lab 详情页头「更多」占位（不接生产 overflow 动作）。
const List<M3EMenuNode> kMd3eLabComicDetailMoreMenuEntries = <M3EMenuNode>[
  M3EMenuEntry(label: 'Lab · 分享'),
];

/// Lab：目录条目 → 详情（preview 数据；[rootNavigator: false]）。
Future<void> openLabCatalogDetail(
  BuildContext context, {
  required LibraryDisplayTarget displayTarget,
  required int catalogIndex,
}) {
  final OverlayRouteScopeSnapshot scope = OverlayRouteScopeSnapshot.capture(
    context,
  );
  return Navigator.of(context, rootNavigator: false).push<void>(
    sharedAxisRoute<void>(
      context,
      builder: (BuildContext routeContext) {
        return overlayRouteScope(
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
    final ComicDetailViewObject entry =
        Md3eLabCatalogDetailPreviewData.comicDetail(catalogIndex: catalogIndex);
    return ComicDetailLayout(
      entry: entry,
      onBack: () => Navigator.of(context).maybePop(),
      moreMenuEntries: kMd3eLabComicDetailMoreMenuEntries,
      onRead: () {
        openLabReader(
          context,
          preview: md3eReaderPreviewDataForComicDetail(entry),
        );
      },
      onReadIncognito: () {
        openLabReader(
          context,
          preview: md3eReaderPreviewDataForComicDetail(entry),
        );
      },
      onEdit: () {
        showComicMetadataEditLayout(
          context: context,
          initialDraft: ComicMetadataEditDraft.fromEntry(entry),
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
    final SeriesDetailViewObject entry =
        Md3eLabCatalogDetailPreviewData.seriesDetail(
          catalogIndex: catalogIndex,
        );
    return SeriesDetailPageLabHost(
      entry: entry,
      onBack: () => Navigator.of(context).maybePop(),
      onEdit: () {
        showSeriesMetadataEditLayout(
          context: context,
          initialDraft: SeriesMetadataEditDraft.fromEntry(entry),
        );
      },
      onComicTap: (int comicIndex) {
        final ComicDetailViewObject comicEntry =
            Md3eLabCatalogDetailPreviewData.comicDetailFromSeriesVolume(
              series: entry,
              comicIndex: comicIndex,
            );
        final OverlayRouteScopeSnapshot scope =
            OverlayRouteScopeSnapshot.capture(context);
        Navigator.of(context, rootNavigator: false).push<void>(
          sharedAxisRoute<void>(
            context,
            builder: (BuildContext routeContext) {
              return overlayRouteScope(
                scope: scope,
                child: ComicDetailLayout(
                  entry: comicEntry,
                  onBack: () => Navigator.of(routeContext).maybePop(),
                  moreMenuEntries: kMd3eLabComicDetailMoreMenuEntries,
                  onRead: () {
                    openLabReader(
                      routeContext,
                      preview: md3eReaderPreviewDataForComicDetail(comicEntry),
                    );
                  },
                  onReadIncognito: () {
                    openLabReader(
                      routeContext,
                      preview: md3eReaderPreviewDataForComicDetail(comicEntry),
                    );
                  },
                  onEdit: () {
                    showComicMetadataEditLayout(
                      context: routeContext,
                      initialDraft: ComicMetadataEditDraft.fromEntry(
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
