import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/shared/ui/motion/desktop_page_transition.dart';
import 'package:hentai_library/features/library_browse/public.dart';
import 'package:hentai_library/features/named_metadata/public.dart';
import 'package:hentai_library/features/read_session/public.dart';
import 'package:hentai_library/features/bootstrap/presentation/views/routing/route_not_found_page.dart';

typedef ComicDetailBuilder = Widget Function(
  BuildContext context,
  String comicId,
);
typedef SeriesDetailBuilder = Widget Function(
  BuildContext context,
  String seriesId,
);

Widget buildSharedComicDetailPage(BuildContext context, String comicId) {
  return ComicDetailMd3ePage(comicId: comicId);
}

Widget buildSharedSeriesDetailPage(BuildContext context, String seriesId) {
  return SeriesDetailMd3ePage(seriesId: seriesId);
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
      pageBuilder: (BuildContext context, GoRouterState state) {
        final String comicId = Uri.decodeComponent(state.pathParameters['id']!);
        return buildDesktopFadeThroughPage(
          state: state,
          child: resolvedComicDetailBuilder(context, comicId),
        );
      },
    ),
    // Saved path / Selected Paths 已退役（ADR-0014）；旧深链回 Home。
    GoRoute(
      path: '/paths',
      redirect: (BuildContext context, GoRouterState state) => '/home',
    ),
    GoRoute(
      path: '/metadata',
      name: '管理',
      pageBuilder: (BuildContext context, GoRouterState state) =>
          buildShellNavPage(
            state: state,
            child: const MetadataManagementPage(),
          ),
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
      path: '/parodies',
      redirect: (BuildContext context, GoRouterState state) =>
          '/metadata?tab=parodies',
    ),
    GoRoute(
      path: '/characters',
      redirect: (BuildContext context, GoRouterState state) =>
          '/metadata?tab=characters',
    ),
    GoRoute(
      path: '/author/:id',
      name: '作者详情',
      pageBuilder: (BuildContext context, GoRouterState state) {
        final int? authorId = int.tryParse(state.pathParameters['id'] ?? '');
        return buildDesktopFadeThroughPage(
          state: state,
          child: authorId == null
              ? const RouteNotFoundPage()
              : AuthorDetailMd3ePage(authorId: authorId),
        );
      },
    ),
    GoRoute(
      path: '/series/:id',
      name: '系列详情',
      pageBuilder: (BuildContext context, GoRouterState state) {
        final String seriesId = Uri.decodeComponent(
          state.pathParameters['id']!,
        );
        return buildDesktopFadeThroughPage(
          state: state,
          child: resolvedSeriesDetailBuilder(context, seriesId),
        );
      },
    ),
    GoRoute(
      path: '/series',
      name: '页面不存在',
      pageBuilder: (BuildContext context, GoRouterState state) =>
          buildDesktopFadeThroughPage(
            state: state,
            child: const RouteNotFoundPage(),
          ),
    ),
    GoRoute(
      path: '/reader',
      name: ReaderRouteArgs.readerRouteName,
      pageBuilder: (BuildContext context, GoRouterState state) {
        final ReaderRouteArgs args = ReaderRouteArgs.fromQuery(
          state.uri.queryParameters,
        );
        return buildDesktopFadeThroughPage(
          state: state,
          child: ReaderMd3ePage(
            comicId: args.comicId,
            keepControlsOpen: args.keepControlsOpen,
            incognito: args.incognito,
            startFromFirstPage: args.startFromFirstPage,
          ),
        );
      },
    ),
  ];
}
