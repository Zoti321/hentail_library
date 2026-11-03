import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/bootstrap/di/composition_overrides.dart';
import 'package:hentai_library/features/reading_history/presentation/patterns/history/history_browse_page.dart';
import 'package:hentai_library/features/reading_history/presentation/patterns/history/history_page_header.dart';
import 'package:hentai_library/features/reading_history/presentation/views/history_page.dart';
import 'package:hentai_library/features/reading_history/public.dart';
import 'package:hentai_library/shared/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/shared/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/features/reading_history/domain/reading_history_repository.dart';
import 'package:hentai_library/shared/di/data_providers.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:riverpod/misc.dart' show Override;

import 'package:hentai_library/shared/ui/theme/app_m3e_theme.dart';
import '../../../../support/pump_localized_app.dart';
import '../../../../support/test_view.dart';

void main() {
  group('History production page', () {
    testWidgets('compact page shows nav menu and MD3E header', (
      WidgetTester tester,
    ) async {
      await _pumpHistoryPage(tester, viewportWidth: 360);

      expect(tester.takeException(), isNull);
      expect(find.byType(HistoryBrowsePage<HistoryCardItem>), findsOneWidget);
      expect(find.byType(Md3eHistoryPageHeader), findsOneWidget);
      expect(find.text('阅读历史'), findsOneWidget);
      expect(find.byIcon(Symbols.menu), findsOneWidget);
    });

    testWidgets('medium page hides nav menu', (WidgetTester tester) async {
      await _pumpHistoryPage(tester, viewportWidth: 700);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.byIcon(Symbols.menu), findsNothing);
    });

    testWidgets('places summary below header without search field', (
      WidgetTester tester,
    ) async {
      await _pumpHistoryPage(tester, viewportWidth: 700);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.textContaining('条记录'), findsOneWidget);
      expect(find.text('搜索历史记录...'), findsNothing);
      final Offset title = tester.getTopLeft(find.text('阅读历史'));
      final Offset subtitle = tester.getTopLeft(find.textContaining('条记录'));
      expect(subtitle.dy, greaterThan(title.dy));
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
        tester.element(find.byType(Md3eHistoryPageHeader)),
      );
      expect(theme.typeScale.titleMedium.fontFamily, kMd3eAppFontFamily);
    });
  });
}

Future<void> _pumpHistoryPage(
  WidgetTester tester, {
  required double viewportWidth,
}) async {
  configureTestView(tester, Size(viewportWidth, 800));

  await pumpLocalizedApp(
    tester,
    home: const Scaffold(body: HistoryPage()),
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
    return PagedResult<ReadingHistory>(
      items: <ReadingHistory>[
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
      ],
      totalCount: 2,
      page: request.page,
      pageSize: request.pageSize,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
