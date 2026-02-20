import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/nav/metadata_page/metadata_management_page.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/reader_page/reader_page.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/selected_paths_page/selected_paths_page.dart';
import 'package:hentai_library/presentation/ui/shared/routing/reader_route_args.dart';

typedef ComicDetailBuilder =
    Widget Function(BuildContext context, String comicId);
typedef SeriesDetailBuilder =
    Widget Function(BuildContext context, String seriesName);

List<RouteBase> buildSharedContentRoutes({
  required ComicDetailBuilder comicDetailBuilder,
  required SeriesDetailBuilder seriesDetailBuilder,
}) {
  return <RouteBase>[
    GoRoute(
      path: '/comic/:id',
      name: '漫画详情',
      builder: (context, state) {
        final String comicId = Uri.decodeComponent(state.pathParameters['id']!);
        return comicDetailBuilder(context, comicId);
      },
    ),
    GoRoute(
      path: '/paths',
      name: '选中路径',
      builder: (context, state) => const SelectedPathsPage(),
    ),
    GoRoute(
      path: '/metadata',
      name: '资料管理',
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
      path: '/series/:name',
      name: '系列详情',
      builder: (context, state) {
        final String seriesName = state.pathParameters['name']!;
        return seriesDetailBuilder(context, seriesName);
      },
    ),
    GoRoute(
      path: '/series',
      redirect: (BuildContext context, GoRouterState state) =>
          '/metadata?tab=series',
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
          readType: args.readType,
          seriesName: args.seriesName,
          keepControlsOpen: args.keepControlsOpen,
        );
      },
    ),
  ];
}
