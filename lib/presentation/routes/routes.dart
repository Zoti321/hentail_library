import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/presentation/pages/app_shell/app_shell.dart';
import 'package:hentai_library/presentation/pages/app_shell/views/comic_detail_page.dart';
import 'package:hentai_library/presentation/pages/app_shell/views/selected_paths_page.dart';
import 'package:hentai_library/presentation/pages/app_shell/views/history_page.dart';
import 'package:hentai_library/presentation/pages/app_shell/views/home_page.dart';
import 'package:hentai_library/presentation/pages/app_shell/views/library_page.dart';
import 'package:hentai_library/presentation/pages/app_shell/views/settings_page.dart';
import 'package:hentai_library/presentation/pages/app_shell/views/series_detail_page.dart';
import 'package:hentai_library/presentation/pages/app_shell/views/series_management_page.dart';
import 'package:hentai_library/presentation/pages/app_shell/views/tag_management_page.dart';
import 'package:hentai_library/presentation/pages/reader_page.dart';
import 'package:hentai_library/presentation/routes/reader_route_args.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/home',
  routes: <RouteBase>[
    ShellRoute(
      builder: (context, state, child) {
        return AppShell(routeChild: child);
      },
      routes: [
        GoRoute(
          path: '/home',
          name: '主页',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: '/local',
          name: '本地漫画',
          builder: (context, state) => const LibraryPage(),
        ),
        GoRoute(
          path: '/comic/:id',
          name: '漫画详情',
          builder: (context, state) {
            final comicId = Uri.decodeComponent(state.pathParameters['id']!);
            return ComicDetailPage(comicId: comicId);
          },
        ),
        GoRoute(
          path: '/paths',
          name: '选中路径',
          builder: (context, state) => const SelectedPathsPage(),
        ),
        GoRoute(
          path: '/history',
          name: '历史记录',
          builder: (context, state) => const HistoryPage(),
        ),
        GoRoute(
          path: '/settings',
          name: '设置',
          builder: (context, state) => const SettingsPage(),
        ),
        GoRoute(
          path: '/tags',
          name: '标签管理',
          builder: (context, state) => const TagManagementPage(),
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
            // go_router 已对路径段做百分号解码；再调用 Uri.decodeComponent
            // 会在系列名含字面量「%」或非法转义时抛出 Illegal percent encoding。
            final String seriesName = state.pathParameters['name']!;
            return SeriesDetailPage(seriesName: seriesName);
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
            );
          },
        ),
      ],
    ),
  ],
);
