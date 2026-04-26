import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/detail/comic_detail_page/comic_detail_page.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/detail/series_detail_page/series_detail_page.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/nav/history_page.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/nav/home_page/home_page.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/nav/library_page/library_page.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/nav/settings_page/settings_page.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/searched_page.dart';
import 'package:hentai_library/presentation/ui/shared/routing/shared_content_routes.dart';
import 'package:hentai_library/presentation/ui/shared/shell/adaptive_app_shell.dart';

final GlobalKey<NavigatorState> desktopRootNavigatorKey =
    GlobalKey<NavigatorState>();

final GoRouter desktopRouter = GoRouter(
  navigatorKey: desktopRootNavigatorKey,
  initialLocation: '/home',
  routes: <RouteBase>[
    ShellRoute(
      builder: (BuildContext context, GoRouterState state, Widget child) {
        return AdaptiveAppShell(routeChild: child);
      },
      routes: <RouteBase>[
        GoRoute(
          path: '/home',
          name: '主页',
          builder: (BuildContext context, GoRouterState state) =>
              const HomePage(),
        ),
        GoRoute(
          path: '/local',
          name: '本地漫画',
          builder: (BuildContext context, GoRouterState state) =>
              const LibraryPage(),
        ),
        GoRoute(
          path: '/history',
          name: '历史记录',
          builder: (BuildContext context, GoRouterState state) =>
              const HistoryPage(),
        ),
        GoRoute(
          path: '/searched',
          name: '搜索结果',
          builder: (BuildContext context, GoRouterState state) {
            final String query = state.uri.queryParameters['q'] ?? '';
            return SearchedPage(query: query);
          },
        ),
        GoRoute(
          path: '/settings',
          name: '设置',
          builder: (BuildContext context, GoRouterState state) =>
              const SettingsPage(),
        ),
        ...buildSharedContentRoutes(
          comicDetailBuilder: (BuildContext context, String comicId) =>
              ComicDetailPage(comicId: comicId),
          seriesDetailBuilder: (BuildContext context, String seriesName) =>
              SeriesDetailPage(seriesName: seriesName),
        ),
      ],
    ),
  ],
);
