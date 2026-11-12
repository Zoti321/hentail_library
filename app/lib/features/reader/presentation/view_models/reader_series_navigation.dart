import 'package:hentai_library/core/constants/app_routes.dart';
import 'package:hentai_library/features/reader/application/open_reader_args.dart';
import 'package:hentai_library/features/reader/application/read_session_application_service.dart';
import 'package:hentai_library/features/reader/presentation/providers/session_providers.dart';
import 'package:hentai_library/features/reader/presentation/routing/reader_route_args.dart';
import 'package:hentai_library/features/reader/presentation/view_models/reader_auto_play_carry.dart';
import 'package:hentai_library/features/reader/presentation/view_models/reader_navigation_intent.dart';
import 'package:hentai_library/features/reader/presentation/view_models/reader_prefetch_notifier.dart';
import 'package:hentai_library/features/reader/presentation/view_models/reader_view_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reader_series_navigation.g.dart';

@Riverpod(keepAlive: true)
class ReaderSeriesNavigation extends _$ReaderSeriesNavigation {
  @override
  void build() {}

  /// 准备切卷并返回路由意图；不触碰 GoRouter。
  Future<ReaderReplaceReaderRouteIntent?> prepareSwitchComic({
    required OpenReaderArgs currentSession,
    required String targetComicId,
  }) async {
    if (targetComicId == currentSession.comicId) {
      return null;
    }
    final ReaderViewModelKey viewKey = readerViewModelKey(
      currentSession.comicId,
      incognito: currentSession.incognito,
      startFromFirstPage: currentSession.startFromFirstPage,
    );
    final bool carryAutoPlay =
        ref
            .read(readerViewModelProvider(viewKey))
            .asData
            ?.value
            .autoPlayEnabled ??
        false;
    ref.read(readerAutoPlayCarryProvider.notifier).arm(carryAutoPlay);

    final ReadSessionApplicationService sessions = ref.read(
      readSessionApplicationServiceProvider,
    );
    int? currentPageIndex;
    if (!currentSession.incognito) {
      currentPageIndex = ref
          .read(readerViewModelProvider(viewKey))
          .asData
          ?.value
          .currentIndex;
    }
    final SeriesSwitchPlan plan = await sessions.prepareSeriesSwitch(
      currentSession: currentSession,
      targetComicId: targetComicId,
      currentPageIndex: currentPageIndex,
    );
    ref
        .read(readerPrefetchNotifierProvider.notifier)
        .clearComic(plan.closeComicId);
    try {
      await ref
          .read(readerPrefetchNotifierProvider.notifier)
          .warmOpenComic(comicId: plan.targetComicId);
    } catch (_) {
      // warm-open 失败不阻断切卷导航。
    }
    return ReaderReplaceReaderRouteIntent(
      AppRoutes.readerLocation(
        ReaderRouteArgs.fromSession(plan.nextSession).toQueryParameters(),
      ),
    );
  }
}
