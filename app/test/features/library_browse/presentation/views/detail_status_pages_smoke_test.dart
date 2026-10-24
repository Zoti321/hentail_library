import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/library_page_comics_providers.dart';
import 'package:hentai_library/features/library_browse/presentation/views/comic_detail_page/comic_detail_page.dart';
import 'package:hentai_library/features/library_browse/presentation/views/series_detail_page/series_detail_page.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;

import '../../../../support/localized_test_app.dart';
import '../../../../support/pump_localized_app.dart';

/// ComicDetailPage 的返回逻辑依赖 GoRouter（`context.canPop()`），需在路由下挂载。
Future<void> _pumpComicDetail(
  WidgetTester tester,
  String comicId,
  List<Override> overrides,
) async {
  final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) =>
            ComicDetailPage(comicId: comicId),
      ),
    ],
  );
  addTearDown(router.dispose);
  final config = localizedTestAppConfig();
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(
        locale: config.locale,
        localizationsDelegates: config.delegates,
        supportedLocales: config.locales,
        theme: buildAppTheme(Brightness.light),
        routerConfig: router,
      ),
    ),
  );
}

/// 详情页边缘状态冒烟：真实页面 + 共用脚手架，验证文案与按钮接线。
void main() {
  testWidgets('series detail shows not-found text with the series id', (
    WidgetTester tester,
  ) async {
    await pumpLocalizedApp(
      tester,
      home: const SeriesDetailPage(seriesId: 'series-missing'),
      overrides: <Override>[
        seriesByIdStateProvider.overrideWith(
          (Ref ref, String seriesId) async => null,
        ),
      ],
    );
    await tester.pumpAndSettle();

    final AppLocalizations l10n = AppLocalizations.of(
      tester.element(find.byType(SeriesDetailPage)),
    );
    expect(
      find.text(l10n.seriesDetailNotFound('series-missing')),
      findsOneWidget,
    );
  });

  testWidgets('series detail shows load error without a retry action', (
    WidgetTester tester,
  ) async {
    await pumpLocalizedApp(
      tester,
      home: const SeriesDetailPage(seriesId: 'series-broken'),
      overrides: <Override>[
        seriesByIdStateProvider.overrideWith(
          (Ref ref, String seriesId) async => throw Exception('boom'),
        ),
      ],
    );
    await tester.pumpAndSettle();

    final AppLocalizations l10n = AppLocalizations.of(
      tester.element(find.byType(SeriesDetailPage)),
    );
    expect(
      find.textContaining(l10n.seriesDetailLoadFailed('')),
      findsOneWidget,
    );
    expect(find.byType(TextButton), findsNothing);
  });

  testWidgets('comic detail shows not-found text and go-to-library action', (
    WidgetTester tester,
  ) async {
    await _pumpComicDetail(tester, 'comic-missing', <Override>[
      libraryComicDetailProvider('comic-missing')
          .overrideWith((Ref ref) async => null),
    ]);
    await tester.pumpAndSettle();

    final AppLocalizations l10n = AppLocalizations.of(
      tester.element(find.byType(ComicDetailPage)),
    );
    expect(find.text(l10n.comicDetailNotFound), findsOneWidget);
    expect(find.text(l10n.comicDetailGoToLibrary), findsOneWidget);
  });

  testWidgets('comic detail error shows retry action', (
    WidgetTester tester,
  ) async {
    await _pumpComicDetail(tester, 'comic-broken', <Override>[
      libraryComicDetailProvider('comic-broken')
          .overrideWith((Ref ref) async => throw Exception('boom')),
      libraryRefreshActionProvider.overrideWithValue(() {}),
    ]);
    await tester.pumpAndSettle();

    final AppLocalizations l10n = AppLocalizations.of(
      tester.element(find.byType(ComicDetailPage)),
    );
    expect(find.text(l10n.comicDetailLoadFailedRetry), findsOneWidget);
    expect(find.text(l10n.shellRetry), findsOneWidget);
  });
}
