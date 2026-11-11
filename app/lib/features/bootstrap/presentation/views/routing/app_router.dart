import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/features/library_browse/public.dart';
import 'package:hentai_library/features/app_settings/public.dart';
import 'package:hentai_library/features/home/public.dart';
import 'package:hentai_library/features/library_admin/public.dart';
import 'package:hentai_library/features/reading_history/public.dart';
import 'package:hentai_library/core/constants/app_routes.dart';
import 'package:hentai_library/features/bootstrap/presentation/views/application_shell.dart';
import 'package:hentai_library/features/bootstrap/presentation/views/routing/shared_content_routes.dart';
import 'package:hentai_library/features/comic_trash/public.dart';
import 'package:hentai_library/shared/di/browse_library_scope_providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final GlobalKey<NavigatorState> appRootNavigatorKey =
    GlobalKey<NavigatorState>();

String? _librariesRedirect(BuildContext context, GoRouterState state) {
  return AppRoutes.legacyRedirectPath(state.uri.path);
}

final GoRouter appRouter = GoRouter(
  navigatorKey: appRootNavigatorKey,
  initialLocation: AppRoutes.home,
  routes: <RouteBase>[
    ShellRoute(
      builder: (BuildContext context, GoRouterState state, Widget child) {
        return ApplicationShell(routeChild: child);
      },
      routes: <RouteBase>[
        GoRoute(
          path: AppRoutes.home,
          name: AppRoutes.homeName,
          pageBuilder: (BuildContext context, GoRouterState state) =>
              buildShellNavPage(
                state: state,
                child: HomePage(
                  libraryManagementSection: const HomeLibraryManagementPanel(),
                ),
              ),
        ),
        GoRoute(
          path: AppRoutes.libraries,
          redirect: _librariesRedirect,
          routes: <RouteBase>[
            // Legacy bookmark: never treat `all` as a library id.
            GoRoute(
              path: AppRoutes.legacyAllSegment,
              redirect: (BuildContext context, GoRouterState state) =>
                  AppRoutes.home,
            ),
            GoRoute(
              path: ':libraryId',
              name: AppRoutes.libraryName,
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
          path: AppRoutes.local,
          name: AppRoutes.localName,
          redirect: (BuildContext context, GoRouterState state) =>
              AppRoutes.home,
        ),
        GoRoute(
          path: AppRoutes.history,
          name: AppRoutes.historyName,
          pageBuilder: (BuildContext context, GoRouterState state) =>
              buildShellNavPage(state: state, child: const HistoryPage()),
        ),
        GoRoute(
          path: AppRoutes.trash,
          name: AppRoutes.trashName,
          pageBuilder: (BuildContext context, GoRouterState state) =>
              buildShellNavPage(state: state, child: const TrashPage()),
        ),
        GoRoute(
          path: AppRoutes.settings,
          name: AppRoutes.settingsName,
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
