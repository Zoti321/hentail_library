import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/pages/md3e_comic_detail_entry.dart';
import 'package:hentai_library/md3e/pages/md3e_reader_page_lab_host.dart';
import 'package:hentai_library/md3e/motion/md3e_shared_axis_route.dart';
import 'package:hentai_library/md3e/patterns/reader/md3e_reader_page_preview_data.dart';
import 'package:hentai_library/md3e/widgets/sheets/md3e_overlay_route_scope.dart';

/// Lab：详情 / 目录 → [Md3eReaderPageLabHost]（preview 会话；不接 read_session FRB）。
Future<void> openMd3eLabReader(
  BuildContext context, {
  Md3eReaderPagePreviewData? preview,
}) {
  final Md3eReaderPagePreviewData data =
      preview ?? Md3eReaderPagePreviewData.sample();
  final Md3eOverlayRouteScopeSnapshot scope =
      Md3eOverlayRouteScopeSnapshot.capture(context);

  return Navigator.of(context, rootNavigator: false).push<void>(
    md3eSharedAxisRoute<void>(
      context,
      builder: (BuildContext routeContext) {
        return md3eOverlayRouteScope(
          scope: scope,
          child: Md3eReaderPageLabHost(
            preview: data,
            onBack: () => Navigator.of(routeContext).maybePop(),
          ),
        );
      },
    ),
  );
}

Md3eReaderPagePreviewData md3eReaderPreviewDataForComicDetail(
  Md3eComicDetailEntry entry,
) {
  final int totalPages = entry.pageCount ?? 24;
  return Md3eReaderPagePreviewData(
    title: entry.title,
    totalPages: totalPages,
    initialPage: 1,
  );
}
