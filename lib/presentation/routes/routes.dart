import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/presentation/pages/app_shell/app_shell.dart';
import 'package:hentai_library/presentation/pages/app_shell/views/comic_detail_page.dart';
import 'package:hentai_library/presentation/pages/app_shell/views/directory_page.dart';
import 'package:hentai_library/presentation/pages/app_shell/views/history_page.dart';
import 'package:hentai_library/presentation/pages/app_shell/views/home_page.dart';
import 'package:hentai_library/presentation/pages/app_shell/views/library_page.dart';
import 'package:hentai_library/presentation/pages/app_shell/views/settings_page.dart';
import 'package:hentai_library/presentation/pages/app_shell/views/tag_management_page.dart';
import 'package:hentai_library/presentation/pages/reader_page.dart';

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
          path: '/folders',
          name: '本地目录',
          builder: (context, state) => const DirectoryPage(),
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
      ],
    ),
    GoRoute(
      path: '/reader/:id',
      name: '阅读页面',
      builder: (context, state) {
        final comicId = Uri.decodeComponent(state.pathParameters['id']!);
        return ReaderPage(comicId: comicId);
      },
    ),
  ],
);
