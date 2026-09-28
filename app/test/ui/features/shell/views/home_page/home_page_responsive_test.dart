import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/domain/models/read_models/home_page_read_models.dart';
import 'package:hentai_library/ui/core/layout/app_layout_breakpoints.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/navigation/desktop_sidebar.dart';
import 'package:hentai_library/ui/features/shell/view_models/scan_library_controller.dart';
import 'package:hentai_library/ui/features/shell/view_models/home_page_dashboard_notifier.dart';
import 'package:hentai_library/ui/features/shell/views/home_page/widgets/home_page_header.dart';
import 'package:hentai_library/ui/features/shell/views/home_page/home_page.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:riverpod/misc.dart' show Override;

void main() {
  group('HomePage responsive layout', () {
    testWidgets('compact width uses row header and single-column stats', (
      WidgetTester tester,
    ) async {
      await _pumpHomePage(tester, const Size(360, 900));

      expect(tester.takeException(), isNull);
      _expectHeaderWithoutScan(tester);
      _expectMenuIcon(tester, findsOneWidget);
      _expectStatsSingleColumn(tester);
    });

    testWidgets('medium width uses 2x2 stats grid', (
      WidgetTester tester,
    ) async {
      await _pumpHomePage(tester, const Size(700, 900));

      expect(tester.takeException(), isNull);
      _expectHeaderWithoutScan(tester);
      _expectMenuIcon(tester, findsNothing);
      _expectStatsGrid2x2(tester);
    });

    testWidgets('expanded width uses single-row stats', (
      WidgetTester tester,
    ) async {
      await _pumpHomePage(tester, const Size(1200, 900));

      expect(tester.takeException(), isNull);
      _expectHeaderWithoutScan(tester);
      _expectMenuIcon(tester, findsNothing);
      _expectStatsSingleRow(tester);
    });

    testWidgets('does not render header scan button', (
      WidgetTester tester,
    ) async {
      await _pumpHomePage(tester, const Size(1200, 900));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('扫描漫画库'), findsNothing);
    });

    testWidgets('renders continue reading history link', (
      WidgetTester tester,
    ) async {
      await _pumpHomePage(tester, const Size(700, 900));
      await tester.pumpAndSettle();

      expect(find.textContaining('查看全部'), findsOneWidget);
    });

    testWidgets('renders home library alert when provided', (
      WidgetTester tester,
    ) async {
      await _pumpHomePage(
        tester,
        const Size(700, 900),
        overrides: _homePageTestOverrides(
          alerts: <HomeLibraryAlert>[
            const HomeLibraryAlert(
              libraryId: 'lib-1',
              displayName: '测试库',
              kind: HomeLibraryAlertKind.staleSync,
              staleDays: 3,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('测试库'), findsOneWidget);
      expect(find.text('扫描漫画库'), findsOneWidget);
    });

    testWidgets('shows empty onboarding without scan CTA when library empty', (
      WidgetTester tester,
    ) async {
      await _pumpHomePage(
        tester,
        const Size(700, 900),
        overrides: _homePageTestOverrides(
          counts: const HomePageCounts(
            comicCount: 0,
            tagCount: 0,
            seriesCount: 0,
            authorCount: 0,
            libraryCount: 0,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('扫描漫画库'), findsNothing);
      expect(find.textContaining('添加本地库'), findsOneWidget);
    });

    testWidgets('moves greeting subtitle into body below header', (
      WidgetTester tester,
    ) async {
      await _pumpHomePage(tester, const Size(700, 900));

      expect(tester.takeException(), isNull);
      expect(find.byType(HomePageHeaderSection), findsOneWidget);
      expect(find.textContaining('，读者'), findsOneWidget);
      final Offset title = tester.getTopLeft(find.text('首页'));
      final Offset greeting = tester.getTopLeft(find.textContaining('，读者'));
      expect(greeting.dy, greaterThan(title.dy));
    });

    testWidgets('uses responsive title sizes by breakpoint', (
      WidgetTester tester,
    ) async {
      await _pumpHomePage(tester, const Size(360, 900));
      expect(tester.widget<Text>(find.text('首页')).style?.fontSize, 18);

      await _pumpHomePage(tester, const Size(700, 900));
      expect(tester.widget<Text>(find.text('首页')).style?.fontSize, 22);

      await _pumpHomePage(tester, const Size(1200, 900));
      expect(tester.widget<Text>(find.text('首页')).style?.fontSize, 26);
    });

    testWidgets(
      'medium window with sidebar-narrowed content hides header menu',
      (WidgetTester tester) async {
        const Size windowSize = Size(650, 900);
        const double contentWidth = 650 - DesktopSidebar.collapsedWidth;
        expect(contentWidth, lessThan(AppLayoutBreakpoints.compact));

        await _pumpHomePage(tester, windowSize, contentWidth: contentWidth);

        expect(tester.takeException(), isNull);
        expect(tester.widget<Text>(find.text('首页')).style?.fontSize, 18);
        _expectMenuIcon(tester, findsNothing);
      },
    );
  });
}

Future<void> _pumpHomePage(
  WidgetTester tester,
  Size viewportSize, {
  double? contentWidth,
  List<Override>? overrides,
}) async {
  tester.view.physicalSize = viewportSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides ?? _homePageTestOverrides(),
      child: MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAppTheme(Brightness.light),
        home: MediaQuery(
          data: MediaQueryData(size: viewportSize),
          child: Scaffold(
            body: SizedBox(
              width: contentWidth ?? viewportSize.width,
              height: viewportSize.height,
              child: const HomePage(),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

List<Override> _homePageTestOverrides({
  HomePageCounts counts = const HomePageCounts(
    comicCount: 12,
    tagCount: 8,
    seriesCount: 3,
    authorCount: 5,
    libraryCount: 1,
  ),
  List<HomeLibraryAlert> alerts = const <HomeLibraryAlert>[],
}) {
  return <Override>[
    homePageCountsStreamProvider.overrideWith(
      (Ref ref) => Stream<HomePageCounts>.value(counts),
    ),
    homeContinueReadingTop5StreamProvider.overrideWith(
      (Ref ref) => Stream<List<HomeContinueReadingEntry>>.value(
        const <HomeContinueReadingEntry>[],
      ),
    ),
    homeRecentlyAddedStreamProvider.overrideWith(
      (Ref ref) => Stream<List<HomeRecentlyAddedEntry>>.value(
        const <HomeRecentlyAddedEntry>[],
      ),
    ),
    homeLibraryAlertsStreamProvider.overrideWith(
      (Ref ref) => Stream<List<HomeLibraryAlert>>.value(alerts),
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

void _expectMenuIcon(WidgetTester tester, Matcher matcher) {
  expect(
    find.byWidgetPredicate(
      (Widget widget) => widget is Icon && widget.icon == LucideIcons.menu,
    ),
    matcher,
  );
}

void _expectHeaderWithoutScan(WidgetTester tester) {
  expect(find.text('扫描漫画库'), findsNothing);
  expect(find.text('首页'), findsOneWidget);
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
