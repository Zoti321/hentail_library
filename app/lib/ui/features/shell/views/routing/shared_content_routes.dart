import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/ui/features/library/views/comic_detail_page/comic_detail_page.dart';
import 'package:hentai_library/ui/features/library/views/series_detail_page/series_detail_page.dart';
import 'package:hentai_library/ui/features/metadata/views/metadata_page/metadata_management_page.dart';
import 'package:hentai_library/ui/features/reader/reader.dart';
import 'package:hentai_library/ui/features/shell/views/routing/route_not_found_page.dart';
import 'package:hentai_library/ui/features/shell/views/selected_paths_page/selected_paths_page.dart';
import 'package:hentai_library/ui/features/shell/views/routing/reader_route_args.dart';

typedef ComicDetailBuilder =
    Widget Function(BuildContext context, String comicId);
typedef SeriesDetailBuilder =
    Widget Function(BuildContext context, String seriesId);

Widget buildSharedComicDetailPage(BuildContext context, String comicId) {
  return ComicDetailPage(comicId: comicId);
}

Widget buildSharedSeriesDetailPage(BuildContext context, String seriesId) {
  return SeriesDetailPage(seriesId: seriesId);
}

List<RouteBase> buildSharedContentRoutes({
  ComicDetailBuilder? comicDetailBuilder,
  SeriesDetailBuilder? seriesDetailBuilder,
}) {
  final ComicDetailBuilder resolvedComicDetailBuilder =
      comicDetailBuilder ?? buildSharedComicDetailPage;
  final SeriesDetailBuilder resolvedSeriesDetailBuilder =
      seriesDetailBuilder ?? buildSharedSeriesDetailPage;
  return <RouteBase>[
    GoRoute(
      path: '/comic/:id',
      name: '漫画详情',
      builder: (context, state) {
        final String comicId = Uri.decodeComponent(state.pathParameters['id']!);
        return resolvedComicDetailBuilder(context, comicId);
      },
    ),
    GoRoute(
      path: '/paths',
      name: '选中路径',
      builder: (context, state) => const SelectedPathsPage(),
    ),
    GoRoute(
      path: '/metadata',
      name: '管理',
      builder: (context, state) => const MetadataManagementPage(),
    ),
    GoRoute(
      path: '/tags',
      redirect: (BuildContext context, GoRouterState state) =>
          '/metadata?tab=tags',
    ),
    GoRoute(
      path: '/authors',
      redirect: (BuildContext context, GoRouterState state) =>
          '/metadata?tab=authors',
    ),
    GoRoute(
      path: '/series/:id',
      name: '系列详情',
      builder: (context, state) {
        final String seriesId = Uri.decodeComponent(
          state.pathParameters['id']!,
        );
        return resolvedSeriesDetailBuilder(context, seriesId);
      },
    ),
    GoRoute(
      path: '/series',
      name: '页面不存在',
      builder: (BuildContext context, GoRouterState state) =>
          const RouteNotFoundPage(),
    ),
    GoRoute(
      path: '/reader',
      name: ReaderRouteArgs.readerRouteName,
      builder: (context, state) {
        final ReaderRouteArgs args = ReaderRouteArgs.fromQuery(
          state.uri.queryParameters,
        );
        return ReaderPage(
          comicId: args.comicId,
          seriesId: args.seriesId,
          keepControlsOpen: args.keepControlsOpen,
          incognito: args.incognito,
        );
      },
    ),
  ];
}
