import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/shared/ui/motion/desktop_page_transition.dart';
import 'package:hentai_library/features/library_browse/public.dart';
import 'package:hentai_library/features/app_settings/public.dart';
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

String? _librariesRedirect(BuildContext context, GoRouterState state) {
  return LibrariesRoutes.redirectPath(locationPath: state.uri.path);
}

final GoRouter appRouter = GoRouter(
  navigatorKey: appRootNavigatorKey,
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
              buildShellNavPage(state: state, child: const HomePage()),
        ),
        GoRoute(
          path: LibrariesRoutes.root,
          redirect: _librariesRedirect,
          routes: <RouteBase>[
            // Legacy bookmark: never treat `all` as a library id.
            GoRoute(
              path: LibrariesRoutes.legacyAllSegment,
              redirect: (BuildContext context, GoRouterState state) => '/home',
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
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: '/local',
          name: '本地漫画',
          redirect: (BuildContext context, GoRouterState state) => '/home',
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
              buildShellNavPage(state: state, child: const TrashPage()),
        ),
        GoRoute(
          path: '/settings',
          name: '设置',
          pageBuilder: (BuildContext context, GoRouterState state) =>
              buildShellNavPage(state: state, child: const SettingsPage()),
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
      // 先抓住 notifier：dispose 后不能再用 ref。
      final BrowseLibraryId scope = ref.read(browseLibraryIdProvider.notifier);
      var cancelled = false;
      int? epoch;
      // claim/release 必须离开 build；epoch 防止旧页 dispose 清掉新页已 claim 的 id。
      Future<void>.microtask(() {
        if (cancelled) {
          return;
        }
        epoch = scope.claim(scopedId);
      });
      return () {
        cancelled = true;
        Future<void>.microtask(() {
          final int? claimed = epoch;
          if (claimed == null) {
            return;
          }
          scope.release(claimed);
        });
      };
    }, <Object?>[libraryId]);

    return const LibraryPage();
  }
}
