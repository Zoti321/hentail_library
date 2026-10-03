import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/domain/repositories/named_facet_management_repository.dart';
import 'package:hentai_library/ui/core/widgets/actions/destructive_filled_button.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/core/widgets/element/chip/outlined_meta_chip.dart';
import 'package:hentai_library/ui/features/metadata/view_models/named_facet_management_controller.dart';
import 'package:hentai_library/ui/features/metadata/views/metadata_page/widgets/metadata_layout_constants.dart';
import 'package:hentai_library/ui/features/metadata/views/metadata_page/widgets/named_facet_fill_viewport.dart';
import 'package:hentai_library/ui/features/metadata/views/metadata_page/widgets/named_facet_management_panel.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:riverpod/misc.dart' show Override;

import '../../../../../support/pump_localized_app.dart';

void main() {
  group('Named facet management panel', () {
    testWidgets(
      'tag chip shows attachment count and does not open a dialog on tap',
      (WidgetTester tester) async {
        await _pumpPanel(
          tester,
          repo: _FakeRepo(tags: <String>['标签 A']),
          kind: ManagedNamedFacetKind.tag,
        );

        expect(find.byType(OutlinedMetaChip), findsOneWidget);
        expect(find.text('标签 A'), findsOneWidget);
        expect(find.text('3'), findsOneWidget);

        await tester.tap(find.text('标签 A'));
        await tester.pumpAndSettle();

        expect(find.text('重命名'), findsNothing);
        expect(find.text('附着漫画数'), findsNothing);
      },
    );

    testWidgets('desktop right-click opens rename merge delete menu', (
      WidgetTester tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      await _pumpPanel(
        tester,
        repo: _FakeRepo(tags: <String>['标签 A']),
        kind: ManagedNamedFacetKind.tag,
      );

      await tester.tap(find.text('标签 A'), buttons: kSecondaryButton);
      await tester.pumpAndSettle();

      expect(find.text('重命名'), findsOneWidget);
      expect(find.text('合并'), findsOneWidget);
      expect(find.text('删除'), findsOneWidget);

      final InkWell mergeItem = tester.widget<InkWell>(
        find
            .ancestor(of: find.text('合并'), matching: find.byType(InkWell))
            .first,
      );
      expect(mergeItem.onTap, isNull);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('mobile long-press opens the same context menu', (
      WidgetTester tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      await _pumpPanel(
        tester,
        repo: _FakeRepo(tags: <String>['标签 A']),
        kind: ManagedNamedFacetKind.tag,
      );

      await tester.longPress(find.text('标签 A'));
      await tester.pumpAndSettle();

      expect(find.text('重命名'), findsOneWidget);
      expect(find.text('合并'), findsOneWidget);
      expect(find.text('删除'), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('search filters with pinyin-assisted match via listAll', (
      WidgetTester tester,
    ) async {
      final _FakeRepo repo = _FakeRepo(authors: <String>['张三', '李四', 'Alpha']);
      late WidgetRef widgetRef;
      await _pumpPanel(
        tester,
        repo: repo,
        onRef: (WidgetRef ref) => widgetRef = ref,
      );

      await widgetRef
          .read(
            namedFacetManagementControllerProvider(
              ManagedNamedFacetKind.author,
            ).notifier,
          )
          .setQuery('zs');
      await tester.pumpAndSettle();

      expect(find.text('张三'), findsOneWidget);
      expect(find.text('李四'), findsNothing);
      expect(find.text('Alpha'), findsNothing);
      expect(repo.listAllCalls, greaterThan(0));
    });

    testWidgets('loadMore appends next page when keyword empty', (
      WidgetTester tester,
    ) async {
      final List<String> authors = List<String>.generate(
        90,
        (int i) => '作者 ${i.toString().padLeft(2, '0')}',
      );
      final _FakeRepo repo = _FakeRepo(authors: authors);
      late WidgetRef widgetRef;
      await _pumpPanel(
        tester,
        repo: repo,
        onRef: (WidgetRef ref) => widgetRef = ref,
        enableFillViewport: false,
      );

      expect(find.byType(OutlinedMetaChip), findsNWidgets(80));

      await widgetRef
          .read(
            namedFacetManagementControllerProvider(
              ManagedNamedFacetKind.author,
            ).notifier,
          )
          .loadMore();
      await tester.pumpAndSettle();

      expect(find.byType(OutlinedMetaChip), findsNWidgets(90));
      expect(repo.fetchPageCalls, greaterThanOrEqualTo(2));
    });

    testWidgets(
      'short first page auto-continues loadMore without user scroll',
      (WidgetTester tester) async {
        final List<String> authors = List<String>.generate(
          100,
          (int i) => '作者 ${i.toString().padLeft(2, '0')}',
        );
        final _FakeRepo repo = _FakeRepo(authors: authors);
        await _pumpPanel(
          tester,
          repo: repo,
          viewportSize: const Size(1200, 2400),
        );

        expect(repo.fetchPageCalls, greaterThanOrEqualTo(2));
        expect(find.byType(OutlinedMetaChip), findsNWidgets(100));
        expect(find.text('已显示全部'), findsOneWidget);
        expect(find.text('加载更多'), findsNothing);
        expect(find.text('滚动到底部以加载更多'), findsNothing);
      },
    );

    testWidgets(
      'footer load-more button shows only when more remains and loads next page',
      (WidgetTester tester) async {
        final List<String> authors = List<String>.generate(
          100,
          (int i) => '作者 ${i.toString().padLeft(2, '0')}',
        );
        final Completer<PagedResult<String>> page2 =
            Completer<PagedResult<String>>();
        final _FakeRepo repo = _FakeRepo(
          authors: authors,
          pageCompleters: <int, Completer<PagedResult<String>>>{2: page2},
        );
        await _pumpPanel(
          tester,
          repo: repo,
          // Short viewport so auto-fill does not immediately exhaust pages.
          viewportSize: const Size(1200, 400),
          enableFillViewport: false,
        );

        expect(find.text('加载更多'), findsOneWidget);
        expect(find.byType(GhostButton), findsOneWidget);
        expect(find.text('滚动到底部以加载更多'), findsNothing);
        expect(find.byType(OutlinedMetaChip), findsNWidgets(80));

        await tester.tap(find.text('加载更多'));
        await tester.pump();

        expect(find.text('正在加载更多…'), findsOneWidget);
        expect(find.text('加载更多'), findsNothing);

        page2.complete(
          PagedResult<String>(
            items: authors.sublist(80),
            totalCount: authors.length,
            page: 2,
            pageSize: kNamedFacetManagementPageSize,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(OutlinedMetaChip), findsNWidgets(100));
        expect(find.text('已显示全部'), findsOneWidget);
        expect(find.text('加载更多'), findsNothing);
      },
    );

    testWidgets('search mode hides load-more button', (
      WidgetTester tester,
    ) async {
      final List<String> authors = List<String>.generate(
        100,
        (int i) => '作者 ${i.toString().padLeft(2, '0')}',
      );
      late WidgetRef widgetRef;
      await _pumpPanel(
        tester,
        repo: _FakeRepo(authors: authors),
        onRef: (WidgetRef ref) => widgetRef = ref,
        enableFillViewport: false,
      );

      expect(find.text('加载更多'), findsOneWidget);

      await widgetRef
          .read(
            namedFacetManagementControllerProvider(
              ManagedNamedFacetKind.author,
            ).notifier,
          )
          .setQuery('作者 01');
      await tester.pumpAndSettle();

      expect(find.text('加载更多'), findsNothing);
      expect(find.text('正在加载更多…'), findsNothing);
    });

    testWidgets('auto-fill stops on loadMore error and keeps retry UI', (
      WidgetTester tester,
    ) async {
      final List<String> authors = List<String>.generate(
        100,
        (int i) => '作者 ${i.toString().padLeft(2, '0')}',
      );
      final _FakeRepo repo = _FakeRepo(authors: authors, failOnPage: 2);
      await _pumpPanel(
        tester,
        repo: repo,
        viewportSize: const Size(1200, 2400),
      );

      expect(repo.fetchPageCalls, 2);
      expect(find.byType(OutlinedMetaChip), findsNWidgets(80));
      expect(find.textContaining('page 2 failed'), findsOneWidget);
      expect(find.text('加载更多'), findsOneWidget);
    });

    testWidgets(
      'delete confirm uses DestructiveFilledButton and user-facing copy',
      (WidgetTester tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.windows;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);

        await _pumpPanel(
          tester,
          repo: _FakeRepo(tags: <String>['标签 A']),
          kind: ManagedNamedFacetKind.tag,
        );

        await tester.tap(find.text('标签 A'), buttons: kSecondaryButton);
        await tester.pumpAndSettle();
        await tester.tap(find.text('删除'));
        await tester.pumpAndSettle();

        expect(find.text('将删除「标签 A」，并解除与 3 本漫画的附着。此操作不可撤销。'), findsOneWidget);
        expect(find.byType(DestructiveFilledButton), findsOneWidget);
        expect(find.textContaining('Named facet attachment'), findsNothing);
        debugDefaultTargetPlatformOverride = null;
      },
    );

    testWidgets('attachment count failure omits chip count', (
      WidgetTester tester,
    ) async {
      await _pumpPanel(
        tester,
        repo: _FakeRepo(
          tags: <String>['标签 A'],
          countError: Exception('count failed'),
        ),
        kind: ManagedNamedFacetKind.tag,
      );

      expect(find.text('标签 A'), findsOneWidget);
      expect(find.text('3'), findsNothing);
    });
  });
}

Future<void> _pumpPanel(
  WidgetTester tester, {
  required _FakeRepo repo,
  ManagedNamedFacetKind kind = ManagedNamedFacetKind.author,
  void Function(WidgetRef ref)? onRef,
  Size viewportSize = const Size(1200, 900),
  bool enableFillViewport = true,
}) async {
  tester.view.physicalSize = viewportSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);

  final ScrollController scrollController = ScrollController();
  addTearDown(scrollController.dispose);

  await pumpLocalizedApp(
    tester,
    wrapProviderScope: true,
    overrides: <Override>[
      namedFacetManagementRepoProvider.overrideWithValue(repo),
    ],
    home: Scaffold(
      body: Consumer(
        builder: (BuildContext context, WidgetRef ref, Widget? child) {
          onRef?.call(ref);
          return Stack(
            children: <Widget>[
              CustomScrollView(
                controller: scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: <Widget>[
                  NamedFacetManagementSliverGroup(
                    kind: kind,
                    layoutTier: MetadataLayoutTier.expanded,
                    viewportWidth: viewportSize.width,
                    horizontalPadding: metadataContentHorizontalPadding(
                      MetadataLayoutTier.expanded,
                    ),
                    contentMaxWidth: metadataInnerContentMaxWidth(
                      MetadataLayoutTier.expanded,
                      viewportSize.width,
                    ),
                  ),
                ],
              ),
              if (enableFillViewport)
                NamedFacetFillViewportBinder(
                  scrollController: scrollController,
                  kind: kind,
                ),
            ],
          );
        },
      ),
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle();
}

class _FakeRepo implements NamedFacetManagementRepository {
  _FakeRepo({
    List<String>? authors,
    List<String>? tags,
    this.countCompleter,
    this.countError,
    this.failOnPage,
    this.pageCompleters = const <int, Completer<PagedResult<String>>>{},
  }) : _items = <ManagedNamedFacetKind, List<String>>{
         if (authors != null)
           ManagedNamedFacetKind.author: List<String>.of(authors),
         if (tags != null) ManagedNamedFacetKind.tag: List<String>.of(tags),
       };

  final Map<ManagedNamedFacetKind, List<String>> _items;
  final Completer<int>? countCompleter;
  final Object? countError;
  final int? failOnPage;
  final Map<int, Completer<PagedResult<String>>> pageCompleters;
  int listAllCalls = 0;
  int fetchPageCalls = 0;

  List<String> _for(ManagedNamedFacetKind kind) =>
      List<String>.of(_items[kind] ?? const <String>[]);

  @override
  Future<List<String>> listAll(ManagedNamedFacetKind kind) async {
    listAllCalls += 1;
    return _for(kind);
  }

  @override
  Future<PagedResult<String>> fetchPage(
    ManagedNamedFacetKind kind,
    PageRequest request,
  ) async {
    fetchPageCalls += 1;
    if (failOnPage != null && request.page == failOnPage) {
      throw Exception('page ${request.page} failed');
    }
    final Completer<PagedResult<String>>? delayed =
        pageCompleters[request.page];
    if (delayed != null) {
      return delayed.future;
    }
    final List<String> all = _for(kind);
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
  Future<void> add(ManagedNamedFacetKind kind, String name) async {}

  @override
  Future<void> deleteByNames(
    ManagedNamedFacetKind kind,
    List<String> names,
  ) async {}

  @override
  Future<void> rename(
    ManagedNamedFacetKind kind,
    String oldName,
    String newName,
  ) async {}

  @override
  Future<int> countAttachments(ManagedNamedFacetKind kind, String name) async {
    final Object? error = countError;
    if (error != null) {
      throw error;
    }
    final Completer<int>? completer = countCompleter;
    if (completer != null) {
      return completer.future;
    }
    return 3;
  }
}
