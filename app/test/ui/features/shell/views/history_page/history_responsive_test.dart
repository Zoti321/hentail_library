import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/models/entity/reading_history.dart';
import 'package:hentai_library/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/domain/repositories/reading_history_repository.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:hentai_library/ui/features/shell/views/history_page.dart';
import 'package:hentai_library/ui/features/shell/views/history_page/history_layout_constants.dart';
import 'package:riverpod/misc.dart' show Override;

void main() {
  group('History responsive layout', () {
    testWidgets('compact page uses vertical header without overflow', (
      WidgetTester tester,
    ) async {
      await _pumpHistoryPage(tester, viewportWidth: 360);

      expect(tester.takeException(), isNull);
      final Text title = tester.widget<Text>(find.text('阅读历史'));
      expect(title.style?.fontSize, 18);
      expect(find.text('清空'), findsNothing);
      expect(find.byTooltip('清空阅读历史'), findsOneWidget);
    });

    testWidgets('medium page keeps clear text button and medium title', (
      WidgetTester tester,
    ) async {
      await _pumpHistoryPage(tester, viewportWidth: 700);

      expect(tester.takeException(), isNull);
      final Text title = tester.widget<Text>(find.text('阅读历史'));
      expect(title.style?.fontSize, 22);
      expect(find.text('清空'), findsOneWidget);
    });

    testWidgets('expanded page uses expanded title size', (
      WidgetTester tester,
    ) async {
      await _pumpHistoryPage(tester, viewportWidth: 1200);

      expect(tester.takeException(), isNull);
      final Text title = tester.widget<Text>(find.text('阅读历史'));
      expect(title.style?.fontSize, 26);
    });

    testWidgets('compact grid renders a single column of history cards', (
      WidgetTester tester,
    ) async {
      await _pumpHistoryPage(tester, viewportWidth: 360);
      await tester.pumpAndSettle();

      final HistoryGridMetrics metrics = historyGridMetrics(
        HistoryLayoutTier.compact,
        360,
      );
      expect(metrics.crossAxisCount, 1);
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
    });
  });
}

Future<void> _pumpHistoryPage(
  WidgetTester tester, {
  required double viewportWidth,
}) async {
  tester.view.physicalSize = Size(viewportWidth, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    ProviderScope(
      overrides: _historyPageTestOverrides(),
      child: MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: const Scaffold(
          body: HistoryPage(),
        ),
      ),
    ),
  );
  await tester.pump();
}

List<Override> _historyPageTestOverrides() {
  return <Override>[
    readingHistoryRepoProvider.overrideWithValue(_FakeReadingHistoryRepo()),
  ];
}

class _FakeReadingHistoryRepo implements ReadingHistoryRepository {
  @override
  Stream<List<ReadingHistory>> watchAllHistory() {
    return Stream<List<ReadingHistory>>.value(const <ReadingHistory>[]);
  }

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
          pageIndex: 1,
        ),
        ReadingHistory(
          comicId: 'c2',
          title: 'Beta',
          lastReadTime: DateTime.fromMillisecondsSinceEpoch(2000),
          pageIndex: 2,
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
