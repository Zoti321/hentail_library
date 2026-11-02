import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/features/bootstrap/di/composition_overrides.dart';
import 'package:hentai_library/features/reading_history/presentation/views/history_md3e/history_md3e_browse_page.dart';
import 'package:hentai_library/features/reading_history/presentation/views/history_md3e/history_md3e_page.dart';
import 'package:hentai_library/features/reading_history/presentation/patterns/history/history_page_header.dart';

import 'package:hentai_library/features/reading_history/public.dart';
import 'package:hentai_library/shared/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/shared/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/shared/domain/repositories/reading_history_repository.dart';
import 'package:hentai_library/shared/di/data_providers.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:riverpod/misc.dart' show Override;

void main() {
  group('History MD3E production page', () {
    testWidgets('compact page shows nav menu and MD3E header', (
      WidgetTester tester,
    ) async {
      await _pumpHistoryPage(tester, viewportWidth: 360);

      expect(tester.takeException(), isNull);
      expect(find.byType(HistoryMd3eBrowsePage), findsOneWidget);
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
  tester.view.physicalSize = Size(viewportWidth, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    ProviderScope(
      overrides: _historyPageTestOverrides(),
      child: MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAppTheme(Brightness.light),
        home: const Scaffold(body: HistoryMd3ePage()),
      ),
    ),
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
