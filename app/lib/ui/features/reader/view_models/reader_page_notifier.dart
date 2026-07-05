import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/ui/features/reader/view_models/read_session_providers.dart';
import 'package:hentai_library/ui/features/reader/view_models/reader_window_fullscreen.dart';
import 'package:hentai_library/ui/features/reader/view_models/series_reader_provider.dart';
import 'package:hentai_library/ui/features/shell/state/reading_aggregate_notifier.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:hentai_library/ui/features/shell/views/routing/reader_route_args.dart';
import 'package:hentai_library/ui/features/reader/views/desktop/reader_page/widgets/reader_route_context.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reader_page_notifier.freezed.dart';
part 'reader_page_notifier.g.dart';

enum ReaderTapZone { left, center, right }

typedef ReaderViewKey = ({String comicId, bool incognito});

ReaderViewKey readerViewKey(String comicId, {bool incognito = false}) =>
    (comicId: comicId, incognito: incognito);

@freezed
abstract class ReaderViewState with _$ReaderViewState {
  factory ReaderViewState({
    required Comic comic,
    @Default(false) bool isVertical,
    @Default(false) bool showControls,
    @Default(1) int currentIndex,
    int? totalPagesOverride,
  }) = _ReaderViewState;

  ReaderViewState._();

  int get totalPages => totalPagesOverride ?? 0;
}

class ReaderPageViewModel {
  const ReaderPageViewModel({
    required this.viewState,
    required this.navContext,
    required this.preferredPageIndex,
  });
  final ReaderViewState viewState;
  final ReaderNavContextData navContext;
  final int? preferredPageIndex;
}

@riverpod
AsyncValue<ReaderPageViewModel> readerPageViewModel(
  Ref ref, {
  required String comicId,
  required bool isSeriesMode,
  String? seriesId,
  bool incognito = false,
}) {
  final AsyncValue<ReaderViewState> viewAsync = ref.watch(
    readerViewProvider(readerViewKey(comicId, incognito: incognito)),
  );
  final AsyncValue<ReaderSeriesContextData> seriesContextAsync = ref.watch(
    readerSeriesContextForReaderProvider(
      comicId: comicId,
      isSeriesMode: isSeriesMode,
      seriesId: seriesId,
      incognito: incognito,
    ),
  );
  if (viewAsync.hasError) {
    return AsyncError(viewAsync.error!, viewAsync.stackTrace!);
  }
  if (seriesContextAsync.hasError) {
    return AsyncError(
      seriesContextAsync.error!,
      seriesContextAsync.stackTrace!,
    );
  }
  final ReaderViewState? viewState = viewAsync.asData?.value;
  final ReaderSeriesContextData? seriesContext =
      seriesContextAsync.asData?.value;
  if (viewState == null || seriesContext == null) {
    return const AsyncLoading();
  }
  return AsyncData(
    ReaderPageViewModel(
      viewState: viewState,
      navContext: seriesContext.navContext,
      preferredPageIndex: seriesContext.preferredPageIndex,
    ),
  );
}

@riverpod
class ReaderViewNotifier extends _$ReaderViewNotifier {
  @override
  Future<ReaderViewState> build(ReaderViewKey key) async {
    final String id = key.comicId;
    final bool incognito = key.incognito;
    final comic = await ref.read(comicRepoProvider).findById(id);
    if (comic == null) {
      throw StateError('Comic not found: $id');
    }
    final images = await ref.watch(comicImagesProvider(comicId: id).future);
    final totalPages = images.length;
    final int oneBased;
    if (incognito) {
      oneBased = 1;
    } else {
      final progress = await ref.watch(
        readingProgressProvider(comicId: id).future,
      );
      oneBased = (progress?.pageIndex ?? 1).clamp(
        1,
        totalPages > 0 ? totalPages : 1,
      );
    }
    return ReaderViewState(
      comic: comic,
      currentIndex: oneBased,
      totalPagesOverride: totalPages > 0 ? totalPages : null,
    );
  }

  String get _comicId => (ref.$arg as ReaderViewKey).comicId;

  void _updateDataState(ReaderViewState Function(ReaderViewState) updater) {
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData(updater(current));
  }

  void toggleShowControls() {
    _updateDataState((s) => s.copyWith(showControls: !s.showControls));
  }

  void setShowControls(bool value) {
    _updateDataState((s) => s.copyWith(showControls: value));
  }

  void setIsVertical(bool value) {
    _updateDataState((s) => s.copyWith(isVertical: value));
  }

  void nextPage() {
    _updateDataState((s) {
      if (s.currentIndex + 1 > s.totalPages) return s;
      return s.copyWith(currentIndex: s.currentIndex + 1);
    });
  }

  void prevPage() {
    _updateDataState((s) {
      if (s.currentIndex - 1 < 1) return s;
      return s.copyWith(currentIndex: s.currentIndex - 1);
    });
  }

  void setIndex(int index) {
    _updateDataState((s) {
      if (index < 1 || index > s.totalPages) return s;
      return s.copyWith(currentIndex: index);
    });
  }

  void setTotalPagesOverride(int? value) {
    _updateDataState((s) => s.copyWith(totalPagesOverride: value));
  }

  void handleTapZone(ReaderTapZone zone) {
    final current = state.asData?.value;
    if (current == null) return;
    if (current.showControls) {
      toggleShowControls();
      return;
    }
    if (current.isVertical) {
      _handleVerticalTap();
    } else {
      _handleHorizontalTap(zone);
    }
  }

  void _handleVerticalTap() {
    toggleShowControls();
  }

  void _handleHorizontalTap(ReaderTapZone zone) {
    if (zone == ReaderTapZone.left) {
      prevPage();
    } else if (zone == ReaderTapZone.right) {
      nextPage();
    } else {
      toggleShowControls();
    }
  }

  Future<void> executeSaveProgress({
    required ReaderRouteContext routeContext,
  }) async {
    if (routeContext.incognito) {
      return;
    }
    final ReaderViewState? currentState = state.asData?.value;
    if (currentState == null) {
      return;
    }
    await ref
        .read(readingAggregateProvider.notifier)
        .saveProgress(
          comicId: _comicId,
          comic: currentState.comic,
          pageIndex: currentState.currentIndex,
          isSeriesMode: routeContext.isSeriesMode,
          seriesId: routeContext.seriesId,
        );
  }

  Future<void> executeExitReader({
    required BuildContext context,
    required ReaderRouteContext routeContext,
  }) async {
    await ref
        .read(readerWindowFullscreenProvider.notifier)
        .exitFullscreenIfNeeded();
    await executeSaveProgress(routeContext: routeContext);
    if (!context.mounted) {
      return;
    }
    final GoRouter router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
      return;
    }
    final String? seriesId = routeContext.isSeriesMode
        ? routeContext.seriesId
        : null;
    if (seriesId != null) {
      router.goNamed(
        '系列详情',
        pathParameters: <String, String>{'id': seriesId},
      );
      return;
    }
    router.go('/home');
  }

  Future<void> executeSelectComic({
    required BuildContext context,
    required ReaderRouteContext routeContext,
    required String targetComicId,
  }) async {
    await executeSaveProgress(routeContext: routeContext);
    if (!context.mounted) {
      return;
    }
    final bool isSeriesMode = routeContext.isSeriesMode;
    context.pushReplacementNamed(
      ReaderRouteArgs.readerRouteName,
      queryParameters: ReaderRouteArgs(
        comicId: targetComicId,
        readType: isSeriesMode
            ? ReaderRouteArgs.readTypeSeries
            : ReaderRouteArgs.readTypeComic,
        seriesId: routeContext.seriesId,
        keepControlsOpen: true,
        incognito: routeContext.incognito,
      ).toQueryParameters(),
    );
  }
}
