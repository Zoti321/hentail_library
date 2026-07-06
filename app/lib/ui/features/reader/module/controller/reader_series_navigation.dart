import 'package:go_router/go_router.dart';
import 'package:hentai_library/domain/reading/read_session.dart';
import 'package:hentai_library/ui/features/reader/module/controller/reader_controller.dart';
import 'package:hentai_library/ui/features/reader/module/controller/reader_prefetch_controller.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:hentai_library/ui/features/shell/state/reading_aggregate_notifier.dart';
import 'package:hentai_library/ui/features/shell/views/routing/reader_route_args.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reader_series_navigation.g.dart';

@Riverpod(keepAlive: true)
class ReaderSeriesNavigation extends _$ReaderSeriesNavigation {
  @override
  void build() {}

  Future<void> switchComic({
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
    ref
        .read(readerPrefetchControllerProvider.notifier)
        .clearComic(currentSession.comicId);
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
}
