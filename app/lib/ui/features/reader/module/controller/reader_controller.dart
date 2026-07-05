import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/reading/reader_session_snapshot.dart';
import 'package:hentai_library/domain/reading/reading_mode.dart';
import 'package:hentai_library/ui/features/reader/module/session/reader_session_bindings.dart';
import 'package:hentai_library/ui/features/reader/view_models/reader_window_fullscreen.dart';
import 'package:hentai_library/ui/features/reader/view_models/series_reader_provider.dart';
import 'package:hentai_library/ui/features/reader/views/desktop/reader_page/widgets/reader_route_context.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:hentai_library/ui/features/shell/state/reading_aggregate_notifier.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reader_controller.freezed.dart';
part 'reader_controller.g.dart';

enum ReaderTapZone { left, center, right }

typedef ReaderControllerKey = ({String comicId, bool incognito});

ReaderControllerKey readerControllerKey(
  String comicId, {
  bool incognito = false,
}) => (comicId: comicId, incognito: incognito);

@Deprecated('Use readerControllerKey')
typedef ReaderViewKey = ReaderControllerKey;

@Deprecated('Use readerControllerKey')
ReaderControllerKey readerViewKey(String comicId, {bool incognito = false}) =>
    readerControllerKey(comicId, incognito: incognito);

@freezed
abstract class ReaderState with _$ReaderState {
  factory ReaderState({
    required Comic comic,
    @Default(ReadingMode.paged) ReadingMode readingMode,
    @Default(false) bool showControls,
    @Default(1) int currentIndex,
    int? totalPagesOverride,
  }) = _ReaderState;

  ReaderState._();

  int get totalPages => totalPagesOverride ?? 0;
}

@Deprecated('Use ReaderState')
typedef ReaderViewState = ReaderState;

class ReaderPageViewModel {
  const ReaderPageViewModel({
    required this.viewState,
    required this.sessionContext,
  });
  final ReaderState viewState;
  final ReadSessionContextData sessionContext;

  ReaderNavContextData get navContext => sessionContext.navContext;
  int? get preferredPageIndex => sessionContext.preferredPageIndex;
  bool get isSeriesRead => sessionContext.isSeriesRead;
  String? get seriesId => sessionContext.seriesId;
}

@riverpod
AsyncValue<ReaderPageViewModel> readerPageViewModel(
  Ref ref, {
  required String comicId,
  String? seriesId,
  bool incognito = false,
}) {
  final AsyncValue<ReaderState> viewAsync = ref.watch(
    readerControllerProvider(
      readerControllerKey(comicId, incognito: incognito),
    ),
  );
  final AsyncValue<ReadSessionContextData> sessionContextAsync = ref.watch(
    readSessionContextForReaderProvider(
      comicId: comicId,
      seriesId: seriesId,
      incognito: incognito,
    ),
  );
  if (viewAsync.hasError) {
    return AsyncError(viewAsync.error!, viewAsync.stackTrace!);
  }
  if (sessionContextAsync.hasError) {
    return AsyncError(
      sessionContextAsync.error!,
      sessionContextAsync.stackTrace!,
    );
  }
  final ReaderState? viewState = viewAsync.asData?.value;
  final ReadSessionContextData? sessionContext =
      sessionContextAsync.asData?.value;
  if (viewState == null || sessionContext == null) {
    return const AsyncLoading();
  }
  return AsyncData(
    ReaderPageViewModel(viewState: viewState, sessionContext: sessionContext),
  );
}

@riverpod
class ReaderController extends _$ReaderController {
  @override
  Future<ReaderState> build(ReaderControllerKey key) async {
    final String id = key.comicId;
    final bool incognito = key.incognito;
    final ReaderSessionSnapshot snapshot = await ref.watch(
      readerSessionOpenProvider(comicId: id, incognito: incognito).future,
    );
    return ReaderState(
      comic: snapshot.comic,
      currentIndex: snapshot.resumePageIndex,
      totalPagesOverride: snapshot.totalPages > 0 ? snapshot.totalPages : null,
    );
  }

  String get _comicId => (ref.$arg as ReaderControllerKey).comicId;

  void _notifyPageChanged(int pageIndex) {
    final ReaderControllerKey key = ref.$arg as ReaderControllerKey;
    if (key.incognito) {
      return;
    }
    ref.read(readingAggregateProvider.notifier).updatePage(pageIndex);
  }

  void _updateDataState(ReaderState Function(ReaderState) updater) {
    final current = state.asData?.value;
    if (current == null) return;
    final ReaderState next = updater(current);
    if (next.currentIndex != current.currentIndex) {
      _notifyPageChanged(next.currentIndex);
    }
    state = AsyncData(next);
  }

  void toggleShowControls() {
    _updateDataState((s) => s.copyWith(showControls: !s.showControls));
  }

  void setShowControls(bool value) {
    _updateDataState((s) => s.copyWith(showControls: value));
  }

  void setReadingMode(ReadingMode value) {
    _updateDataState((s) => s.copyWith(readingMode: value));
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
    if (current.readingMode.isContinuousVertical) {
      toggleShowControls();
      return;
    }
    _handleHorizontalTap(zone);
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
    final ReaderState? currentState = state.asData?.value;
    if (currentState != null) {
      ref
          .read(readingAggregateProvider.notifier)
          .updatePage(currentState.currentIndex);
    }
    await ref.read(readingAggregateProvider.notifier).flushProgress();
  }

  Future<void> closeSession() async {
    await ref.read(readerSessionServiceProvider).close(_comicId);
  }

  Future<void> executeExitReader({
    required BuildContext context,
    required ReaderRouteContext routeContext,
  }) async {
    await ref
        .read(readerWindowFullscreenProvider.notifier)
        .exitFullscreenIfNeeded();
    if (!routeContext.incognito) {
      final ReaderState? currentState = state.asData?.value;
      if (currentState != null) {
        ref
            .read(readingAggregateProvider.notifier)
            .updatePage(currentState.currentIndex);
      }
      await ref.read(readingAggregateProvider.notifier).endSession();
    }
    await closeSession();
    if (!context.mounted) {
      return;
    }
    final GoRouter router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
      return;
    }
    router.go('/home');
  }
}