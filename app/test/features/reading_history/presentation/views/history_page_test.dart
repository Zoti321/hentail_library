import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/bootstrap/di/composition_overrides.dart';
import 'package:hentai_library/features/reading_history/presentation/patterns/history/history_browse_page.dart';
import 'package:hentai_library/features/reading_history/presentation/patterns/history/history_page_header.dart';
import 'package:hentai_library/features/reading_history/presentation/widgets/history_list_item.dart';
import 'package:hentai_library/features/reading_history/public.dart';
import 'package:hentai_library/shared/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/shared/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/features/reading_history/domain/reading_history_repository.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:riverpod/misc.dart' show Override;

import '../../../../support/pump_localized_app.dart';

void main() {
  group('History production page', () {
    testWidgets('compact page shows MD3E header without nav menu', (
      WidgetTester tester,
    ) async {
      await _pumpHistoryPage(tester, viewportWidth: 360);

      expect(tester.takeException(), isNull);
      expect(find.byType(HistoryBrowsePage<HistoryCardItem>), findsOneWidget);
      expect(find.byType(HistoryPageHeader), findsOneWidget);
      expect(find.text('阅读历史'), findsOneWidget);
      expect(find.byIcon(Symbols.menu), findsNothing);
    });

    testWidgets('medium page hides nav menu', (WidgetTester tester) async {
      await _pumpHistoryPage(tester, viewportWidth: 700);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.byIcon(Symbols.menu), findsNothing);
    });

    testWidgets('places summary and search field below header', (
      WidgetTester tester,
    ) async {
      await _pumpHistoryPage(tester, viewportWidth: 700);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.textContaining('条记录'), findsOneWidget);
      expect(find.text('搜索历史记录...'), findsOneWidget);
      final Offset title = tester.getTopLeft(find.text('阅读历史'));
      final Offset subtitle = tester.getTopLeft(find.textContaining('条记录'));
      expect(subtitle.dy, greaterThan(title.dy));
    });

    testWidgets('filters list by search keyword and clears immediately', (
      WidgetTester tester,
    ) async {
      await _pumpHistoryPage(tester, viewportWidth: 700);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      Finder listTitle(String title) => find.descendant(
        of: find.byType(HistoryListItem),
        matching: find.text(title),
      );

      expect(listTitle('Alpha'), findsOneWidget);
      expect(listTitle('Beta'), findsOneWidget);

      await tester.enterText(find.byType(EditableText), 'Alpha');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(listTitle('Alpha'), findsOneWidget);
      expect(listTitle('Beta'), findsNothing);
      expect(find.textContaining('1 个结果'), findsOneWidget);

      await tester.tap(find.byIcon(M3EIcons.close));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(listTitle('Alpha'), findsOneWidget);
      expect(listTitle('Beta'), findsOneWidget);
      expect(find.textContaining('个结果'), findsNothing);
    });

    testWidgets('renders grouped history list items', (
      WidgetTester tester,
    ) async {
      await _pumpHistoryPage(tester, viewportWidth: 700);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
      expect(find.textContaining('3/20'), findsOneWidget);
      expect(find.textContaining('2/10'), findsOneWidget);
    });

    testWidgets('production path applies app font on M3E theme', (
      WidgetTester tester,
    ) async {
      await _pumpHistoryPage(tester, viewportWidth: 700);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final M3EThemeData theme = M3ETheme.of(
        tester.element(find.byType(HistoryPageHeader)),
      );
      expect(theme.typeScale.titleMedium.fontFamily, kAppFontFamily);
    });
  });
}

Future<void> _pumpHistoryPage(
  WidgetTester tester, {
  required double viewportWidth,
}) async {
  configureTestView(tester, Size(viewportWidth, 800));

  // Match production [App] builder: ambient M3E already carries app font.
  final AssembledAppTheme assembled = assembleAppTheme(Brightness.light);
  await pumpLocalizedApp(
    tester,
    theme: assembled.material,
    home: M3ETheme(
      data: assembled.m3e,
      child: const Scaffold(body: HistoryPage()),
    ),
    overrides: _historyPageTestOverrides(),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

List<Override> _historyPageTestOverrides() {
  return <Override>[
    ...bootstrapCompositionOverrides(),
    readingHistoryRepoProvider.overrideWithValue(_FakeReadingHistoryRepo()),
  ];
}

class _FakeReadingHistoryRepo implements ReadingHistoryRepository {
  static final List<ReadingHistory> _all = <ReadingHistory>[
    ReadingHistory(
      comicId: 'c1',
      title: 'Alpha',
      lastReadTime: DateTime.fromMillisecondsSinceEpoch(3000),
      pageIndex: 3,
      pageCount: 20,
    ),
    ReadingHistory(
      comicId: 'c2',
      title: 'Beta',
      lastReadTime: DateTime.fromMillisecondsSinceEpoch(2000),
      pageIndex: 2,
      pageCount: 10,
    ),
  ];

  @override
  Stream<void> watchHistoryChanges() {
    return const Stream<void>.empty();
  }

  @override
  Future<Map<String, int>> listReadPageIndexes() async => const <String, int>{};

  @override
  Future<PagedResult<ReadingHistory>> fetchHistoryPage(
    PageRequest request, {
    String? keyword,
  }) async {
    final String needle = keyword?.trim().toLowerCase() ?? '';
    final List<ReadingHistory> items = needle.isEmpty
        ? _all
        : _all
              .where(
                (ReadingHistory item) =>
                    item.title.toLowerCase().contains(needle),
              )
              .toList(growable: false);
    return PagedResult<ReadingHistory>(
      items: items,
      totalCount: items.length,
      page: request.page,
      pageSize: request.pageSize,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
