import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:hentai_library/features/comic/presentation/views/comic_detail/comic_detail_view_object.dart';

import '../../hosts/md3e_reader_page_lab_host.dart';

import 'package:hentai_library/shared/ui/motion/shared_axis_route.dart';

import '../../preview/md3e_reader_page_preview_data.dart';

import 'package:hentai_library/shared/ui/widgets/sheets/overlay_route_scope.dart';

/// Lab：详情 / 目录 → [ReaderPageLabHost]（preview 会话；不接 read_session FRB）。
///
/// 与生产 `/reader` 一致：Shared Axis Z（层级下钻）。
Future<void> openLabReader(
  BuildContext context, {
  ReaderPagePreviewData? preview,
}) {
  final ReaderPagePreviewData data =
      preview ?? ReaderPagePreviewData.sample();
  final OverlayRouteScopeSnapshot scope =
      OverlayRouteScopeSnapshot.capture(context);

  return Navigator.of(context, rootNavigator: false).push<void>(
    sharedAxisRoute<void>(
      context,
      transitionType: SharedAxisTransitionType.scaled,
      builder: (BuildContext routeContext) {
        return overlayRouteScope(
          scope: scope,
          child: ReaderPageLabHost(
            preview: data,
            onBack: () => Navigator.of(routeContext).maybePop(),
          ),
        );
      },
    ),
  );
}

ReaderPagePreviewData md3eReaderPreviewDataForComicDetail(
  ComicDetailViewObject entry,
) {
  final int totalPages = entry.pageCount ?? 24;
  return ReaderPagePreviewData(
    title: entry.title,
    totalPages: totalPages,
    initialPage: 1,
  );
}
