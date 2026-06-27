import 'package:hentai_library/ui/features/library/views/mobile/mobile_comic_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/ui/features/shell/views/mobile/mobile_history_page.dart';
import 'package:hentai_library/ui/features/library/views/mobile/mobile_library_page.dart';
import 'package:hentai_library/ui/features/metadata/views/mobile/mobile_manage_page.dart';
import 'package:hentai_library/ui/features/library/views/mobile/mobile_series_detail_page.dart';
import 'package:hentai_library/ui/features/settings/views/mobile/mobile_settings_page.dart';
import 'package:hentai_library/ui/features/shell/views/routing/shared_content_routes.dart';
import 'package:hentai_library/ui/features/shell/views/adaptive_app_shell.dart';

final GlobalKey<NavigatorState> mobileRootNavigatorKey =
    GlobalKey<NavigatorState>();

final GoRouter mobileRouter = GoRouter(
  navigatorKey: mobileRootNavigatorKey,
  initialLocation: '/local',
  routes: <RouteBase>[
    ShellRoute(
      builder: (BuildContext context, GoRouterState state, Widget child) {
        return AdaptiveAppShell(routeChild: child);
      },
      routes: <RouteBase>[
        GoRoute(
          path: '/home',
          name: '主页(移动)',
          builder: (BuildContext context, GoRouterState state) =>
              const MobileLibraryPage(),
        ),
        GoRoute(
          path: '/local',
          name: '本地漫画',
          builder: (BuildContext context, GoRouterState state) =>
              const MobileLibraryPage(),
        ),
        GoRoute(
          path: '/history',
          name: '历史记录',
          builder: (BuildContext context, GoRouterState state) =>
              const MobileHistoryPage(),
        ),
        GoRoute(
          path: '/settings',
          name: '设置',
          builder: (BuildContext context, GoRouterState state) =>
              const MobileSettingsPage(),
        ),
        GoRoute(
          path: '/manage',
          name: '管理中心',
          builder: (BuildContext context, GoRouterState state) =>
              const MobileManagePage(),
        ),
        ...buildSharedContentRoutes(
          comicDetailBuilder: (BuildContext context, String comicId) =>
              MobileComicDetailPage(comicId: comicId),
          seriesDetailBuilder: (BuildContext context, String seriesName) =>
              MobileSeriesDetailPage(seriesName: seriesName),
        ),
      ],
    ),
  ],
);
