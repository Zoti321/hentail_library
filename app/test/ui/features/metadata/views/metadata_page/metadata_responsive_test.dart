import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/domain/repositories/named_facet_management_repository.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/chrome/capsule_tab_bar.dart';
import 'package:hentai_library/ui/core/widgets/chrome/content_switcher_bottom_bar.dart';
import 'package:hentai_library/ui/core/widgets/element/chip/count_digit_chip.dart';
import 'package:hentai_library/ui/core/widgets/element/chip/outlined_meta_chip.dart';
import 'package:hentai_library/ui/features/metadata/views/metadata_page/metadata_management_page.dart';
import 'package:hentai_library/ui/features/metadata/views/metadata_page/widgets/metadata_layout_constants.dart';
import 'package:hentai_library/ui/features/metadata/views/metadata_page/widgets/named_facet_management_panel.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:riverpod/misc.dart' show Override;

void main() {
  group('Metadata responsive layout', () {
    testWidgets(
      'compact page uses bottom bar, header count chip, and no header tabs',
      (WidgetTester tester) async {
        await _pumpMetadataPage(tester, viewportWidth: 360);

        expect(tester.takeException(), isNull);
        expect(find.text('管理'), findsOneWidget);
        expect(find.byType(CapsuleTabBar), findsNothing);
        expect(find.byType(ContentSwitcherBottomBar), findsOneWidget);
        expect(find.byType(CountDigitChip), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
        expect(find.text('共 2 条'), findsNothing);
        expect(find.text('作者'), findsOneWidget);
        expect(find.text('标签'), findsOneWidget);
        expect(find.text('原作'), findsOneWidget);
        expect(find.text('角色'), findsOneWidget);
      },
    );

    testWidgets('expanded page uses capsule tabs and add icon tooltip', (
      WidgetTester tester,
    ) async {
      await _pumpMetadataPage(tester, viewportWidth: 1200);

      expect(tester.takeException(), isNull);
      expect(find.text('管理'), findsOneWidget);
      expect(find.byType(CapsuleTabBar), findsOneWidget);
      expect(find.byType(ContentSwitcherBottomBar), findsNothing);
      expect(find.byType(CountDigitChip), findsNothing);
      expect(find.text('管理作者与标签'), findsNothing);
      expect(find.byTooltip('添加作者'), findsOneWidget);
      expect(find.textContaining('Ctrl+N'), findsNothing);
      expect(find.text('原作'), findsWidgets);
      expect(find.text('角色'), findsWidgets);
    });

    testWidgets('author panel renders name chips without inline rename', (
      WidgetTester tester,
    ) async {
      await _pumpAuthorPanel(
        tester,
        viewportWidth: 360,
        layoutTier: MetadataLayoutTier.compact,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('作者管理'), findsNothing);
      expect(find.byTooltip('重命名'), findsNothing);
      expect(find.byTooltip('删除已选'), findsNothing);
      expect(find.byType(OutlinedMetaChip), findsNWidgets(2));
      expect(find.text('作者 A'), findsOneWidget);
      expect(find.text('作者 B'), findsOneWidget);
    });

    testWidgets('expanded author panel keeps chip flow without row actions', (
      WidgetTester tester,
    ) async {
      await _pumpAuthorPanel(
        tester,
        viewportWidth: 1200,
        layoutTier: MetadataLayoutTier.expanded,
      );

      expect(tester.takeException(), isNull);
      expect(find.byTooltip('重命名'), findsNothing);
      expect(find.byType(OutlinedMetaChip), findsNWidgets(2));
      expect(find.text('共 2 条'), findsOneWidget);
    });
  });
}

Future<void> _pumpMetadataPage(
  WidgetTester tester, {
  required double viewportWidth,
}) async {
  tester.view.physicalSize = Size(viewportWidth, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    ProviderScope(
      overrides: _metadataTestOverrides(),
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

Future<void> _pumpAuthorPanel(
  WidgetTester tester, {
  required double viewportWidth,
  required MetadataLayoutTier layoutTier,
}) async {
  tester.view.physicalSize = Size(viewportWidth, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    ProviderScope(
      overrides: _metadataTestOverrides(),
      child: MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: CustomScrollView(
            slivers: <Widget>[
              NamedFacetManagementSliverGroup(
                kind: ManagedNamedFacetKind.author,
                layoutTier: layoutTier,
                viewportWidth: viewportWidth,
                horizontalPadding: metadataContentHorizontalPadding(layoutTier),
                contentMaxWidth: metadataInnerContentMaxWidth(
                  layoutTier,
                  viewportWidth,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle();
}

List<Override> _metadataTestOverrides() {
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
  Future<int> countAttachments(ManagedNamedFacetKind kind, String name) async =>
      name == '作者 A' ? 3 : 0;
}
