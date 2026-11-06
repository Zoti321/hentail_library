import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/shared/ui/motion/desktop_page_transition.dart';
import 'package:hentai_library/features/library_browse/public.dart';
import 'package:hentai_library/features/app_settings/public.dart';
import 'package:hentai_library/features/bootstrap/presentation/views/all_libraries_browse_page.dart';
import 'package:hentai_library/features/home/public.dart';
import 'package:hentai_library/features/reading_history/public.dart';
import 'package:hentai_library/core/constants/libraries_routes.dart';
import 'package:hentai_library/features/bootstrap/presentation/views/application_shell.dart';
import 'package:hentai_library/features/bootstrap/presentation/views/routing/shared_content_routes.dart';
import 'package:hentai_library/features/comic_trash/public.dart';
import 'package:hentai_library/shared/di/browse_library_scope_providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final GlobalKey<NavigatorState> appRootNavigatorKey =
    GlobalKey<NavigatorState>();

String? _librariesRootRedirect(BuildContext context, GoRouterState state) {
  if (state.uri.path == LibrariesRoutes.root) {
    return LibrariesRoutes.all;
  }
  return null;
}

final GoRouter appRouter = GoRouter(
  navigatorKey: appRootNavigatorKey,
  observers: <NavigatorObserver>[desktopPageTransitionObserver],
  initialLocation: '/home',
  routes: <RouteBase>[
    ShellRoute(
      builder: (BuildContext context, GoRouterState state, Widget child) {
        return ApplicationShell(routeChild: child);
      },
      routes: <RouteBase>[
        GoRoute(
          path: '/home',
          name: '主页',
          pageBuilder: (BuildContext context, GoRouterState state) =>
              buildShellNavPage(state: state, child: const HomeMd3ePage()),
        ),
        GoRoute(
          path: LibrariesRoutes.root,
          redirect: _librariesRootRedirect,
          routes: <RouteBase>[
            GoRoute(
              path: LibrariesRoutes.allSegment,
              name: '全部库',
              pageBuilder: (BuildContext context, GoRouterState state) =>
                  buildShellNavPage(
                    state: state,
                    child: const AllLibrariesBrowsePage(),
                    allowPendingFadeThrough: true,
                  ),
            ),
            GoRoute(
              path: ':libraryId',
              name: '漫画库',
              pageBuilder: (BuildContext context, GoRouterState state) {
                final String libraryId =
                    state.pathParameters['libraryId'] ?? '';
                return buildShellNavPage(
                  state: state,
                  child: LibraryBrowsePage(libraryId: libraryId),
                  allowPendingFadeThrough: true,
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: '/local',
          name: '本地漫画',
          redirect: (BuildContext context, GoRouterState state) =>
              LibrariesRoutes.all,
        ),
        GoRoute(
          path: '/history',
          name: '历史记录',
          pageBuilder: (BuildContext context, GoRouterState state) =>
              buildShellNavPage(state: state, child: const HistoryPage()),
        ),
        GoRoute(
          path: '/trash',
          name: '已删除',
          pageBuilder: (BuildContext context, GoRouterState state) =>
              buildShellNavPage(state: state, child: const TrashMd3ePage()),
        ),
        GoRoute(
          path: '/settings',
          name: '设置',
          pageBuilder: (BuildContext context, GoRouterState state) =>
              buildShellNavPage(state: state, child: const SettingsMd3ePage()),
        ),
        ...buildSharedContentRoutes(),
      ],
    ),
  ],
);

/// 单库浏览页：注入 [browseLibraryIdProvider] 作用域后展示目录。
class LibraryBrowsePage extends HookConsumerWidget {
  const LibraryBrowsePage({super.key, required this.libraryId});

  final String libraryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      final String? scopedId = libraryId.isEmpty ? null : libraryId;
      Future<void>.microtask(() {
        ref.read(browseLibraryIdProvider.notifier).setId(scopedId);
      });
      return () {
        Future<void>.microtask(() {
          ref.read(browseLibraryIdProvider.notifier).setId(null);
        });
      };
    }, <Object?>[libraryId]);

    return const LibraryMd3ePage();
  }
}
