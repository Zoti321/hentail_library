import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/ui/features/library/views/library_page/library_page.dart';
import 'package:hentai_library/ui/features/library/views/searched_page.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/settings_page.dart';
import 'package:hentai_library/ui/features/shell/state/current_library_notifier.dart';
import 'package:hentai_library/ui/features/shell/views/all_libraries_browse_page.dart';
import 'package:hentai_library/ui/features/shell/views/home_page/home_page.dart';
import 'package:hentai_library/ui/features/shell/views/history_page.dart';
import 'package:hentai_library/ui/features/shell/views/navigation/libraries_routes.dart';
import 'package:hentai_library/ui/features/shell/views/responsive_app_shell.dart';
import 'package:hentai_library/ui/features/shell/views/routing/shared_content_routes.dart';
import 'package:hentai_library/ui/providers.dart';

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
  initialLocation: '/home',
  routes: <RouteBase>[
    ShellRoute(
      builder: (BuildContext context, GoRouterState state, Widget child) {
        return ResponsiveAppShell(routeChild: child);
      },
      routes: <RouteBase>[
        GoRoute(
          path: '/home',
          name: '主页',
          builder: (BuildContext context, GoRouterState state) =>
              const HomePage(),
        ),
        GoRoute(
          path: LibrariesRoutes.root,
          redirect: _librariesRootRedirect,
          routes: <RouteBase>[
            GoRoute(
              path: LibrariesRoutes.allSegment,
              name: '全部库',
              builder: (BuildContext context, GoRouterState state) =>
                  const AllLibrariesBrowsePage(),
            ),
            GoRoute(
              path: ':libraryId',
              name: '漫画库',
              builder: (BuildContext context, GoRouterState state) {
                final String libraryId =
                    state.pathParameters['libraryId'] ?? '';
                return LibraryBrowsePage(libraryId: libraryId);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/local',
          name: '本地漫画',
          builder: (BuildContext context, GoRouterState state) =>
              const LegacyLocalLibraryRedirectPage(),
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

/// Ensures route [libraryId] is selected as Current library, then shows catalog.
class LibraryBrowsePage extends ConsumerStatefulWidget {
  const LibraryBrowsePage({super.key, required this.libraryId});

  final String libraryId;

  @override
  ConsumerState<LibraryBrowsePage> createState() => _LibraryBrowsePageState();
}

class _LibraryBrowsePageState extends ConsumerState<LibraryBrowsePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncCurrent());
  }

  @override
  void didUpdateWidget(covariant LibraryBrowsePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.libraryId != widget.libraryId) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncCurrent());
    }
  }

  Future<void> _syncCurrent() async {
    if (!mounted || widget.libraryId.isEmpty) {
      return;
    }
    final String? currentId = ref
        .read(currentLibraryProvider)
        .asData
        ?.value
        .currentId;
    if (currentId == widget.libraryId) {
      return;
    }
    try {
      await ref.read(currentLibraryProvider.notifier).select(widget.libraryId);
    } catch (_) {
      // Invalid id: leave catalog empty / error surfaces via providers.
    }
  }

  @override
  Widget build(BuildContext context) => const LibraryPage();
}

/// Legacy `/local` bookmark: wait for Current library then redirect.
class LegacyLocalLibraryRedirectPage extends ConsumerWidget {
  const LegacyLocalLibraryRedirectPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<CurrentLibraryState> async = ref.watch(
      currentLibraryProvider,
    );
    return async.when(
      data: (CurrentLibraryState value) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            context.go(LibrariesRoutes.browsePathForCurrent(value.currentId));
          }
        });
        return const Center(child: CircularProgressIndicator());
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object _, StackTrace __) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            context.go(LibrariesRoutes.all);
          }
        });
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
