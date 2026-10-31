import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/features/bootstrap/di/deps.dart';
import 'package:hentai_library/features/named_metadata/presentation/views/metadata_md3e/metadata_md3e_page.dart';
import 'package:hentai_library/shared/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/shared/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/shared/domain/repositories/named_facet_management_repository.dart';
import 'package:hentai_library/md3e/widgets/selection/md3e_segmented_capsule_bar.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';
import 'package:riverpod/misc.dart' show Override;

void main() {
  group('MetadataManagementPage (MD3E)', () {
    testWidgets('compact width shows capsule toolbar without bottom bar', (
      WidgetTester tester,
    ) async {
      await _pumpPage(tester, viewportWidth: 360);

      expect(tester.takeException(), isNull);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byType(Md3eSegmentedCapsuleBar), findsOneWidget);
      expect(find.text('作者 A'), findsOneWidget);
    });

    testWidgets('expanded width renders the page without a bottom bar', (
      WidgetTester tester,
    ) async {
      await _pumpPage(tester, viewportWidth: 1200);

      expect(tester.takeException(), isNull);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('作者 A'), findsOneWidget);
    });
  });
}

Future<void> _pumpPage(
  WidgetTester tester, {
  required double viewportWidth,
}) async {
  tester.view.physicalSize = Size(viewportWidth, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    ProviderScope(
      overrides: _overrides(),
      child: MaterialApp.router(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAppTheme(Brightness.light),
        routerConfig: GoRouter(
          initialLocation: '/metadata?tab=authors',
          routes: <RouteBase>[
            GoRoute(
              path: '/metadata',
              builder: (BuildContext context, GoRouterState state) {
                return const Scaffold(body: MetadataManagementPage());
              },
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle();
}

List<Override> _overrides() {
  return <Override>[
    namedFacetManagementRepoProvider.overrideWithValue(
      _FakeNamedFacetManagementRepository(
        itemsByKind: <ManagedNamedFacetKind, List<String>>{
          ManagedNamedFacetKind.author: <String>['作者 A', '作者 B'],
          ManagedNamedFacetKind.tag: <String>['标签 A'],
          ManagedNamedFacetKind.parody: <String>['原作 A'],
          ManagedNamedFacetKind.character: <String>['角色 A'],
        },
      ),
    ),
  ];
}

class _FakeNamedFacetManagementRepository
    implements NamedFacetManagementRepository {
  _FakeNamedFacetManagementRepository({required this.itemsByKind});

  final Map<ManagedNamedFacetKind, List<String>> itemsByKind;

  List<String> _items(ManagedNamedFacetKind kind) =>
      List<String>.of(itemsByKind[kind] ?? const <String>[]);

  @override
  Future<List<String>> listAll(ManagedNamedFacetKind kind) async =>
      _items(kind);

  @override
  Future<PagedResult<String>> fetchPage(
    ManagedNamedFacetKind kind,
    PageRequest request,
  ) async {
    final List<String> all = _items(kind);
    final int start = request.offset;
    final int end = (start + request.pageSize).clamp(0, all.length);
    return PagedResult<String>(
      items: start >= all.length ? const <String>[] : all.sublist(start, end),
      totalCount: all.length,
      page: request.page,
      pageSize: request.pageSize,
    );
  }

  @override
  Future<void> add(ManagedNamedFacetKind kind, String name) async {
    itemsByKind.putIfAbsent(kind, () => <String>[]).add(name);
  }

  @override
  Future<void> deleteByNames(
    ManagedNamedFacetKind kind,
    List<String> names,
  ) async {
    itemsByKind[kind]?.removeWhere(names.contains);
  }

  @override
  Future<void> rename(
    ManagedNamedFacetKind kind,
    String oldName,
    String newName,
  ) async {
    final List<String>? items = itemsByKind[kind];
    if (items == null) {
      return;
    }
    final int index = items.indexOf(oldName);
    if (index >= 0) {
      items[index] = newName;
    }
  }

  @override
  Future<void> merge(
    ManagedNamedFacetKind kind,
    String sourceName,
    String targetName,
  ) async {
    itemsByKind[kind]?.removeWhere((String name) => name == sourceName);
  }

  @override
  Future<int> countAttachments(ManagedNamedFacetKind kind, String name) async =>
      0;
}
