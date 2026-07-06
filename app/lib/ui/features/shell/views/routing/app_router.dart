import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/ui/features/library/views/library_page/library_page.dart';
import 'package:hentai_library/ui/features/library/views/searched_page.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/settings_page.dart';
import 'package:hentai_library/ui/features/shell/views/adaptive_app_shell.dart';
import 'package:hentai_library/ui/features/shell/views/history_page.dart';
import 'package:hentai_library/ui/features/shell/views/home_page/home_page.dart';
import 'package:hentai_library/ui/features/shell/views/routing/shared_content_routes.dart';

final GlobalKey<NavigatorState> appRootNavigatorKey =
    GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: appRootNavigatorKey,
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
        ...buildSharedContentRoutes(),
      ],
    ),
  ],
);
