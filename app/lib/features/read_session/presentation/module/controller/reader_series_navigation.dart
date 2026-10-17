import 'package:go_router/go_router.dart';
import 'package:hentai_library/features/read_session/domain/read_session.dart';
import 'package:hentai_library/features/read_session/domain/read_session_coordinator.dart';
import 'package:hentai_library/features/read_session/presentation/module/controller/reader_auto_play_carry.dart';
import 'package:hentai_library/features/bootstrap/di/deps.dart';
import 'package:hentai_library/features/bootstrap/presentation/views/routing/reader_route_args.dart';
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
      startFromFirstPage: currentSession.startFromFirstPage,
    );
    final bool carryAutoPlay =
        ref
            .read(readerControllerProvider(viewKey))
            .asData
            ?.value
            .autoPlayEnabled ??
        false;
    ref.read(readerAutoPlayCarryProvider.notifier).arm(carryAutoPlay);

    final ReadSessionCoordinator coordinator = ref.read(
      readSessionCoordinatorProvider,
    );
    int? currentPageIndex;
    if (!currentSession.incognito) {
      currentPageIndex = ref
          .read(readerControllerProvider(viewKey))
          .asData
          ?.value
          .currentIndex;
    }
    final SeriesSwitchPlan plan = await coordinator.prepareSeriesSwitch(
      currentSession: currentSession,
      targetComicId: targetComicId,
      currentPageIndex: currentPageIndex,
    );
    ref
        .read(readerPrefetchControllerProvider.notifier)
        .clearComic(plan.closeComicId);
    try {
      await ref
          .read(readerPrefetchControllerProvider.notifier)
          .warmOpenComic(comicId: plan.targetComicId);
    } catch (_) {
      // warm-open 失败不阻断切卷导航。
    }
    router.pushReplacement(
      Uri(
        path: '/reader',
        queryParameters: ReaderRouteArgs.fromSession(
          plan.nextSession,
        ).toQueryParameters(),
      ).toString(),
    );
  }
}
