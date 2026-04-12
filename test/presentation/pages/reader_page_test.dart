import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/entity/comic/series.dart';
import 'package:hentai_library/domain/entity/comic/series_item.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/reader_page.dart';
import 'package:hentai_library/presentation/ui/desktop/routes/reader_route_args.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  test('ReaderRouteContext normalize series params correctly', () {
    final ReaderRouteContext actual = ReaderRouteContext.normalize(
      comicId: ' comic-1 ',
      readType: 'series',
      seriesName: 'MySeries',
    );
    expect(actual.comicId, 'comic-1');
    expect(actual.readType, ReaderReadType.series);
    expect(actual.seriesName, 'MySeries');
    expect(actual.isSeriesMode, isTrue);
  });
  test('ReaderRouteContext fallback to comic when seriesName missing', () {
    final ReaderRouteContext actual = ReaderRouteContext.normalize(
      comicId: 'comic-2',
      readType: 'series',
      seriesName: '',
    );
    expect(actual.readType, ReaderReadType.comic);
    expect(actual.seriesName, isNull);
    expect(actual.isSeriesMode, isFalse);
  });
  test('buildSeriesReaderNavData sorts and locates index', () {
    final Series series = Series(
      name: 'S',
      items: <SeriesItem>[
        SeriesItem(comicId: 'b', order: 2),
        SeriesItem(comicId: 'a', order: 1),
      ],
    );
    final SeriesReaderNavData? actual = buildSeriesReaderNavData(series, 'b');
    expect(actual, isNotNull);
    expect(actual!.currentIndex, 1);
    expect(
      actual.sortedItems.map((SeriesItem item) => item.comicId).toList(),
      <String>['a', 'b'],
    );
  });
  test('ReaderRouteArgs parses series params correctly', () {
    final ReaderRouteArgs args = ReaderRouteArgs.fromQuery(<String, String>{
      ReaderRouteArgs.readTypeKey: ReaderRouteArgs.readTypeSeries,
      ReaderRouteArgs.comicIdKey: 'comic-3',
      ReaderRouteArgs.seriesNameKey: 'SeriesA',
    });
    expect(args.comicId, 'comic-3');
    expect(args.readType, ReaderRouteArgs.readTypeSeries);
    expect(args.seriesName, 'SeriesA');
    final Map<String, String> query = args.toQueryParameters();
    expect(query[ReaderRouteArgs.comicIdKey], 'comic-3');
    expect(query[ReaderRouteArgs.seriesNameKey], 'SeriesA');
  });
  testWidgets('ReaderPage shows params error when comicId missing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ReaderPage(comicId: '', readType: 'comic'),
        ),
      ),
    );
    expect(find.text('阅读参数错误：缺少 comic_id'), findsOneWidget);
  });
}
