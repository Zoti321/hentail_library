import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/domain/repositories/named_facet_management_repository.dart';
import 'package:hentai_library/ui/core/widgets/actions/destructive_filled_button.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/core/widgets/element/chip/outlined_meta_chip.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/adaptive_form_surface.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/dialog_actions_bar.dart';
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
      'detail shows name title, attachment metric, and footer actions',
      (WidgetTester tester) async {
        await _pumpPanel(tester, repo: _FakeRepo(authors: <String>['作者 A']));

        expect(find.byType(OutlinedMetaChip), findsOneWidget);
        await tester.tap(find.text('作者 A'));
        await tester.pumpAndSettle();

        expect(find.byType(AdaptiveFormSurface), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(AdaptiveFormSurface),
            matching: find.text('作者 A'),
          ),
          findsOneWidget,
        );
        expect(find.text('名称'), findsNothing);
        expect(find.text('附着漫画数'), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
        expect(
          find.textContaining('Named facet attachment count'),
          findsNothing,
        );

        final DialogActionsBar actionsBar = tester.widget(
          find.descendant(
            of: find.byType(AdaptiveFormSurface),
            matching: find.byType(DialogActionsBar),
          ),
        );
        expect(actionsBar.showDivider, isFalse);

        expect(find.text('关闭'), findsOneWidget);
        expect(find.text('重命名'), findsOneWidget);
        expect(find.text('删除'), findsOneWidget);

        final ThemeData footerTheme = Theme.of(
          tester.element(
            find.descendant(
              of: find.byType(DialogActionsBar),
              matching: find.byType(Wrap),
            ),
          ),
        );
        final OutlinedBorder? outlinedShape = footerTheme
            .outlinedButtonTheme
            .style
            ?.shape
            ?.resolve(const <WidgetState>{});
        expect(outlinedShape, isA<RoundedRectangleBorder>());
        expect(
          (outlinedShape! as RoundedRectangleBorder).borderRadius,
          BorderRadius.circular(4),
        );
      },
    );

    testWidgets('delete stays disabled until attachment count is ready', (
      WidgetTester tester,
    ) async {
      final Completer<int> countCompleter = Completer<int>();
      await _pumpPanel(
        tester,
        repo: _FakeRepo(
          authors: <String>['作者 A'],
          countCompleter: countCompleter,
        ),
      );

      await tester.tap(find.text('作者 A'));
      await tester.pump();
      await tester.pump();

      expect(find.text('附着漫画数'), findsOneWidget);
      expect(find.text('加载中…'), findsOneWidget);

      final FilledButton deleteWhileLoading = tester.widget(
        find.widgetWithText(FilledButton, '删除'),
      );
      expect(deleteWhileLoading.onPressed, isNull);

      countCompleter.complete(3);
      await tester.pumpAndSettle();

      expect(find.text('3'), findsOneWidget);
      final FilledButton deleteReady = tester.widget(
        find.widgetWithText(FilledButton, '删除'),
      );
      expect(deleteReady.onPressed, isNotNull);
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
        await _pumpPanel(tester, repo: _FakeRepo(authors: <String>['作者 A']));

        await tester.tap(find.text('作者 A'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('删除'));
        await tester.pumpAndSettle();

        expect(find.text('将删除「作者 A」，并解除与 3 本漫画的附着。此操作不可撤销。'), findsOneWidget);
        expect(find.byType(DestructiveFilledButton), findsOneWidget);
        expect(find.textContaining('Named facet attachment'), findsNothing);
      },
    );

    testWidgets('attachment count failure shows error without number', (
      WidgetTester tester,
    ) async {
      await _pumpPanel(
        tester,
        repo: _FakeRepo(
          authors: <String>['作者 A'],
          countError: Exception('count failed'),
        ),
      );

      await tester.tap(find.text('作者 A'));
      await tester.pumpAndSettle();

      expect(find.text('附着漫画数'), findsOneWidget);
      expect(find.text('3'), findsNothing);
      expect(find.text('加载中…'), findsNothing);
      expect(find.textContaining('count failed'), findsOneWidget);

      final FilledButton delete = tester.widget(
        find.widgetWithText(FilledButton, '删除'),
      );
      expect(delete.onPressed, isNull);
    });
  });
}

Future<void> _pumpPanel(
  WidgetTester tester, {
  required _FakeRepo repo,
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
                    kind: ManagedNamedFacetKind.author,
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
                  kind: ManagedNamedFacetKind.author,
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
    required List<String> authors,
    this.countCompleter,
    this.countError,
    this.failOnPage,
    this.pageCompleters = const <int, Completer<PagedResult<String>>>{},
  }) : _items = <ManagedNamedFacetKind, List<String>>{
         ManagedNamedFacetKind.author: List<String>.of(authors),
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
