import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/models/read_models/home_page_read_models.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/features/shell/state/scan_library_controller.dart';
import 'package:hentai_library/ui/features/shell/view_models/home_page_dashboard_notifier.dart';
import 'package:hentai_library/ui/features/shell/views/home_page/widgets/home_page_header.dart';
import 'package:hentai_library/ui/features/shell/views/home_page/home_page.dart';
import 'package:hentai_library/ui/features/shell/views/home_page/widgets/home_page_constants.dart';
import 'package:riverpod/misc.dart' show Override;

void main() {
  group('HomePage responsive layout', () {
    testWidgets('compact width uses stacked header and single-column stats', (
      WidgetTester tester,
    ) async {
      await _pumpHomePage(tester, const Size(360, 900));

      expect(tester.takeException(), isNull);
      _expectHeaderStacked(tester);
      _expectStatsSingleColumn(tester);
    });

    testWidgets('medium width uses 2x2 stats grid', (WidgetTester tester) async {
      await _pumpHomePage(tester, const Size(700, 900));

      expect(tester.takeException(), isNull);
      _expectHeaderRow(tester);
      _expectStatsGrid2x2(tester);
    });

    testWidgets('expanded width uses single-row stats', (
      WidgetTester tester,
    ) async {
      await _pumpHomePage(tester, const Size(1200, 900));

      expect(tester.takeException(), isNull);
      _expectHeaderRow(tester);
      _expectStatsSingleRow(tester);
    });

    testWidgets('does not render shortcut entries section', (
      WidgetTester tester,
    ) async {
      await _pumpHomePage(tester, const Size(1200, 900));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('快捷入口'), findsNothing);
    });
  });
}

Future<void> _pumpHomePage(WidgetTester tester, Size viewportSize) async {
  tester.view.physicalSize = viewportSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    ProviderScope(
      overrides: _homePageTestOverrides(),
      child: MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: const Scaffold(body: HomePage()),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

List<Override> _homePageTestOverrides() {
  const HomePageCounts counts = HomePageCounts(
    comicCount: 12,
    tagCount: 8,
    seriesCount: 3,
    authorCount: 5,
  );
  return <Override>[
    homePageCountsStreamProvider.overrideWith(
      (Ref ref) => Stream<HomePageCounts>.value(counts),
    ),
    homeContinueReadingTop5StreamProvider.overrideWith(
      (Ref ref) => Stream<List<HomeContinueReadingEntry>>.value(
        const <HomeContinueReadingEntry>[],
      ),
    ),
    scanLibraryControllerProvider.overrideWith(_IdleScanLibraryController.new),
  ];
}

class _IdleScanLibraryController extends ScanLibraryController {
  @override
  ScanLibraryState build() => const ScanLibraryState();
}

Offset _labelOffset(WidgetTester tester, String label) {
  return tester.getTopLeft(find.text(label).first);
}

Offset _headerScanButtonOffset(WidgetTester tester) {
  return tester.getTopLeft(
    find.descendant(
      of: find.byType(HomePageHeader),
      matching: find.text('扫描漫画库'),
    ),
  );
}

void _expectHeaderStacked(WidgetTester tester) {
  final Offset title = _labelOffset(tester, '首页');
  final Offset scanAction = _headerScanButtonOffset(tester);
  expect(scanAction.dy, greaterThan(title.dy + 24));
}

void _expectHeaderRow(WidgetTester tester) {
  final Offset title = _labelOffset(tester, '首页');
  final Offset scanAction = _headerScanButtonOffset(tester);
  expect(scanAction.dx, greaterThan(title.dx + 40));
}

void _expectStatsSingleColumn(WidgetTester tester) {
  const List<String> labels = <String>['漫画库', '作者', '系列', '标签'];
  final List<Offset> offsets = labels
      .map((String label) => _labelOffset(tester, label))
      .toList(growable: false);
  for (int index = 0; index < labels.length - 1; index++) {
    expect(offsets[index].dx, closeTo(offsets[index + 1].dx, 8));
    expect(offsets[index].dy, lessThan(offsets[index + 1].dy));
  }
}

void _expectStatsGrid2x2(WidgetTester tester) {
  final Offset comic = _labelOffset(tester, '漫画库');
  final Offset series = _labelOffset(tester, '系列');
  final Offset author = _labelOffset(tester, '作者');
  final Offset tags = _labelOffset(tester, '标签');

  expect(comic.dy, closeTo(series.dy, 8));
  expect(comic.dx, lessThan(series.dx));
  expect(author.dy, closeTo(tags.dy, 8));
  expect(author.dx, lessThan(tags.dx));
  expect(author.dy, greaterThan(comic.dy + 8));
}

void _expectStatsSingleRow(WidgetTester tester) {
  final Offset comic = _labelOffset(tester, '漫画库');
  final Offset series = _labelOffset(tester, '系列');
  final Offset tags = _labelOffset(tester, '标签');
  final Offset author = _labelOffset(tester, '作者');

  expect(series.dy, closeTo(comic.dy, 8));
  expect(tags.dy, closeTo(comic.dy, 8));
  expect(author.dy, closeTo(comic.dy, 8));
  expect(comic.dx, lessThan(series.dx));
  expect(series.dx, lessThan(tags.dx));
  expect(tags.dx, lessThan(author.dx));
}
