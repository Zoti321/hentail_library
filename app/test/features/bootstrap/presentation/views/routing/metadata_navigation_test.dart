import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/features/bootstrap/presentation/views/routing/go_router_app_navigator.dart';
import 'package:hentai_library/features/bootstrap/presentation/views/routing/shared_content_routes.dart';
import 'package:hentai_library/features/comic_metadata/domain/named_facet_management_repository.dart';
import 'package:hentai_library/features/comic_metadata/presentation/view_models/named_facet_management_view_model.dart';
import 'package:hentai_library/features/comic_metadata/presentation/views/metadata/patterns/management_catalog_toolbar.dart';
import 'package:hentai_library/l10n/app_localizations_zh.dart';
import 'package:hentai_library/shared/application/navigation/app_routes.dart';
import 'package:hentai_library/shared/presentation/providers/app_navigator_provider.dart';

import '../../../../../support/pump_app.dart';

void main() {
  for (final tab in ['authors', 'parodies', 'characters']) {
    testWidgets('Home push opens the requested metadata facet: $tab', (
      tester,
    ) async {
      final router = await _pumpRouter(tester);
      final navigator = GoRouterAppNavigator(router);
      navigator.pushMetadata(tab: tab);
      await tester.pumpAndSettle();
      expect(navigator.queryParameter('tab'), tab);
      expect(navigator.currentPath(), AppRoutes.metadata);
      expect(navigator.currentLocation(), AppRoutes.metadataTab(tab));
      expect(
        tester
            .widget<ManagementCatalogToolbar>(
              find.byType(ManagementCatalogToolbar),
            )
            .facet,
        switch (tab) {
          'authors' => ManagedNamedFacetKind.author,
          'parodies' => ManagedNamedFacetKind.parody,
          _ => ManagedNamedFacetKind.character,
        },
      );
      navigator.pop();
      await tester.pumpAndSettle();
      expect(find.text('home'), findsOneWidget);
      expect(navigator.currentLocation(), AppRoutes.home);
    });
  }

  testWidgets('metadata tabs switch content and keep the Home back stack', (
    tester,
  ) async {
    final router = await _pumpRouter(tester);
    final navigator = GoRouterAppNavigator(router);
    navigator.pushMetadata(tab: 'tags');
    await tester.pumpAndSettle();
    final l10n = AppLocalizationsZh();
    for (final (label, kind) in [
      (l10n.metadataTabAuthors, ManagedNamedFacetKind.author),
      (l10n.metadataTabParodies, ManagedNamedFacetKind.parody),
      (l10n.metadataTabCharacters, ManagedNamedFacetKind.character),
      (l10n.metadataTabTags, ManagedNamedFacetKind.tag),
    ]) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ManagementCatalogToolbar>(
              find.byType(ManagementCatalogToolbar),
            )
            .facet,
        kind,
      );
      expect(navigator.queryParameter('tab'), switch (kind) {
        ManagedNamedFacetKind.author => 'authors',
        ManagedNamedFacetKind.tag => 'tags',
        ManagedNamedFacetKind.parody => 'parodies',
        ManagedNamedFacetKind.character => 'characters',
      });
    }
    navigator.pop();
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('direct metadata navigation and query replacement stay in sync', (
    tester,
  ) async {
    final router = await _pumpRouter(tester);
    final navigator = GoRouterAppNavigator(router);
    navigator.goMetadata(tab: 'characters');
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ManagementCatalogToolbar>(
            find.byType(ManagementCatalogToolbar),
          )
          .facet,
      ManagedNamedFacetKind.character,
    );
    navigator.replaceMetadataTab('authors');
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ManagementCatalogToolbar>(
            find.byType(ManagementCatalogToolbar),
          )
          .facet,
      ManagedNamedFacetKind.author,
    );
    expect(navigator.currentLocation(), AppRoutes.metadataTab('authors'));
  });
}

Future<GoRouter> _pumpRouter(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1000, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final router = GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      ShellRoute(
        builder: (_, _, child) => Scaffold(body: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (_, _) => const Scaffold(body: Text('home')),
          ),
          ...buildSharedContentRoutes(),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  await pumpApp(
    tester,
    overrides: [
      appNavigatorProvider.overrideWithValue(GoRouterAppNavigator(router)),
      for (final kind in ManagedNamedFacetKind.values)
        namedFacetManagementViewModelProvider(kind)
            .overrideWith(_EmptyFacets.new),
    ],
    home: Router.withConfig(config: router),
  );
  await tester.pumpAndSettle();
  return router;
}

class _EmptyFacets extends NamedFacetManagementViewModel {
  @override
  NamedFacetManagementState build(ManagedNamedFacetKind kind) =>
      const NamedFacetManagementState(
        query: '',
        items: [],
        totalCount: 0,
        isLoading: false,
        isLoadingMore: false,
        hasMore: false,
      );
}
