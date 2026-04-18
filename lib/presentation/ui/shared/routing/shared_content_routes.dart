import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/nav_pages/series_management_page.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/nav_pages/author_management_page.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/nav_pages/tag_management_page.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/reader_page.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/selected_paths_page.dart';
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
      path: '/tags',
      name: '标签管理',
      builder: (context, state) => const TagManagementPage(),
    ),
    GoRoute(
      path: '/authors',
      name: '作者管理',
      builder: (context, state) => const AuthorManagementPage(),
    ),
    GoRoute(
      path: '/series',
      name: '系列管理',
      builder: (context, state) => const SeriesManagementPage(),
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
