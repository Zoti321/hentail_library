import 'package:go_router/go_router.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/reading_history.dart';
import 'package:hentai_library/domain/reading/read_session.dart';
import 'package:hentai_library/ui/features/reader/view_models/reader_page_notifier.dart';
import 'package:hentai_library/ui/features/reader/views/desktop/reader_page/widgets/reader_route_context.dart';
import 'package:hentai_library/ui/features/reader/view_models/series_reader_provider.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:hentai_library/ui/features/shell/views/routing/app_router.dart';
import 'package:hentai_library/ui/features/shell/views/routing/reader_route_args.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 打开阅读器；Series read 需传入 [seriesId]。
Future<void> openReadSession(
  WidgetRef ref, {
  required String comicId,
  String? seriesId,
  bool incognito = false,
  bool keepControlsOpen = false,
  bool recordStandaloneStart = true,
}) async {
  final ReadSessionRouteParams session = ReadSessionRouteParams(
    comicId: comicId,
    seriesId: seriesId,
    incognito: incognito,
    keepControlsOpen: keepControlsOpen,
  );
  if (!incognito && recordStandaloneStart && !session.isSeriesRead) {
    final Comic? comic = await ref.read(comicRepoProvider).findById(comicId);
    if (comic != null) {
      await ref.read(readingHistoryRepoProvider).recordReading(
        ReadingHistory(
          comicId: comic.comicId,
          title: comic.title,
          lastReadTime: DateTime.now(),
        ),
      );
    }
  }
  appRouter.pushNamed(
    ReaderRouteArgs.readerRouteName,
    queryParameters: ReaderRouteArgs.fromSession(session).toQueryParameters(),
  );
}

Future<void> openSeriesReadSession(
  WidgetRef ref, {
  required String seriesId,
  bool incognito = false,
}) async {
  final String comicId = await ref.read(
    resolveSeriesReadComicIdProvider(seriesId: seriesId).future,
  );
  if (comicId.isEmpty) {
    return;
  }
  await openReadSession(
    ref,
    comicId: comicId,
    seriesId: seriesId,
    incognito: incognito,
    recordStandaloneStart: false,
  );
}

Future<void> openComicReadSession(
  WidgetRef ref, {
  required Comic comic,
  bool incognito = false,
}) async {
  final String? seriesId = incognito
      ? null
      : await ref.read(
          resolveSeriesIdForComicReadProvider(comicId: comic.comicId).future,
        );
  await openReadSession(
    ref,
    comicId: comic.comicId,
    seriesId: seriesId,
    incognito: incognito,
    recordStandaloneStart: !incognito && seriesId == null,
  );
}

Future<void> navigateToSeriesComicInReader(
  WidgetRef ref, {
  required GoRouter router,
  required ReadSessionRouteParams currentSession,
  required String targetComicId,
}) async {
  if (targetComicId == currentSession.comicId) {
    return;
  }
  final ReaderViewKey viewKey = readerViewKey(
    currentSession.comicId,
    incognito: currentSession.incognito,
  );
  await ref.read(readerViewProvider(viewKey).notifier).executeSaveProgress(
    routeContext: ReaderRouteContext.normalize(
      comicId: currentSession.comicId,
      seriesId: currentSession.seriesId,
      incognito: currentSession.incognito,
    ),
  );
  await ref
      .read(readerSessionServiceProvider)
      .close(currentSession.comicId);
  final ReadSessionRouteParams nextSession = ReadSessionRouteParams(
    comicId: targetComicId,
    seriesId: currentSession.seriesId,
    incognito: currentSession.incognito,
  );
  router.go(
    Uri(
      path: '/reader',
      queryParameters: ReaderRouteArgs.fromSession(nextSession).toQueryParameters(),
    ).toString(),
  );
}
