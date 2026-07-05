import 'package:go_router/go_router.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/reading/read_session.dart';
import 'package:hentai_library/ui/features/reader/module/controller/reader_controller.dart';
import 'package:hentai_library/ui/features/reader/module/controller/reader_prefetch_controller.dart';
import 'package:hentai_library/ui/features/reader/view_models/series_reader_provider.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:hentai_library/ui/features/shell/state/reading_aggregate_notifier.dart';
import 'package:hentai_library/ui/features/shell/views/routing/app_router.dart';
import 'package:hentai_library/ui/features/shell/views/routing/reader_route_args.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 打开阅读器；Series read 需传入 [seriesId]。
Future<void> openReadSession(
  WidgetRef ref, {
  required String comicId,
  String? seriesId,
  bool incognito = false,
  bool keepControlsOpen = false,
}) async {
  final ReadSessionRouteParams session = ReadSessionRouteParams(
    comicId: comicId,
    seriesId: seriesId,
    incognito: incognito,
    keepControlsOpen: keepControlsOpen,
  );
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
  );
}

Future<void> navigateToSeriesComicInReader(
  Ref ref, {
  required GoRouter router,
  required ReadSessionRouteParams currentSession,
  required String targetComicId,
}) async {
  if (targetComicId == currentSession.comicId) {
    return;
  }
  final ReaderControllerKey viewKey = readerControllerKey(
    currentSession.comicId,
    incognito: currentSession.incognito,
  );
  if (!currentSession.incognito) {
    final ReaderState? viewState = ref
        .read(readerControllerProvider(viewKey))
        .asData
        ?.value;
    if (viewState != null) {
      ref
          .read(readingAggregateProvider.notifier)
          .updatePage(viewState.currentIndex);
    }
    await ref.read(readingAggregateProvider.notifier).endSession();
  }
  await ref.read(readerSessionServiceProvider).close(currentSession.comicId);
  ref.read(readerPrefetchControllerProvider.notifier).clearComic(
    currentSession.comicId,
  );
  try {
    await ref
        .read(readerPrefetchControllerProvider.notifier)
        .warmOpenComic(comicId: targetComicId);
  } catch (_) {
    // warm-open 失败不阻断切卷导航。
  }
  final ReadSessionRouteParams nextSession = ReadSessionRouteParams(
    comicId: targetComicId,
    seriesId: currentSession.seriesId,
    incognito: currentSession.incognito,
  );
  router.go(
    Uri(
      path: '/reader',
      queryParameters: ReaderRouteArgs.fromSession(
        nextSession,
      ).toQueryParameters(),
    ).toString(),
  );
}
