import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/shared/ui/motion/catalog_detail_page.dart';
import 'package:hentai_library/shared/ui/motion/desktop_page_transition.dart';
import 'package:hentai_library/shared/ui/motion/motion.dart';
import 'package:hentai_library/shared/ui/motion/shared_axis_route.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';
import 'package:hentai_library/features/comic/public.dart';
import 'package:hentai_library/features/library_browse/public.dart';
import 'package:hentai_library/features/series/public.dart';
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
      pageBuilder: (BuildContext context, GoRouterState state) {
        final String comicId = Uri.decodeComponent(state.pathParameters['id']!);
        return buildCatalogDetailPage(
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
              : AuthorDetailPage(authorId: authorId),
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
        return buildCatalogDetailPage(
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
        // 详情 → 阅读：Shared Axis Z（层级下钻进沉浸页；非水平同级、非 Shell fade-through）。
        return buildSharedAxisPage(
          state: state,
          transitionType: SharedAxisTransitionType.scaled,
          fillColor: context.reader.readerBackground,
          transitionDuration: LabMotion.motionDurationOf(
            context,
            kSharedAxisRouteDuration,
          ),
          child: ReaderPage(
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
