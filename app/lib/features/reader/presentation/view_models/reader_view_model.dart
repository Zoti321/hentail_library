import 'package:hentai_library/features/reader/domain/reader_comic_ref.dart';
import 'package:hentai_library/features/reader/domain/auto_play_boundary_policy.dart';
import 'package:hentai_library/features/reader/application/open_reader_args.dart';
import 'package:hentai_library/features/reader/domain/spread_navigation.dart';
import 'package:hentai_library/features/reader/domain/auto_play_mode.dart';
import 'package:hentai_library/features/reader/domain/reading_mode.dart';
import 'package:hentai_library/features/reader/domain/opened_read_session.dart';
import 'package:hentai_library/features/reader/presentation/input/reader_tap_zone.dart';
import 'package:hentai_library/features/reader/presentation/view_models/reader_auto_play_carry.dart';
import 'package:hentai_library/features/reader/presentation/reader_exit_location.dart';
import 'package:hentai_library/features/reader/presentation/routing/reader_route_context.dart';
import 'package:hentai_library/features/reader/application/read_session_application_service.dart';
import 'package:hentai_library/features/app_settings/public/providers/app_settings_providers.dart';
import 'package:hentai_library/features/app_settings/public/app_settings_cross_feature_types.dart';
import 'package:hentai_library/features/reader/domain/reading_preferences.dart';
import 'package:hentai_library/features/reader/application/reading_preferences_acl.dart';
import 'package:hentai_library/features/reader/presentation/providers/reading_preferences_providers.dart';
import 'package:hentai_library/features/reader/presentation/providers/session_providers.dart';
import 'package:hentai_library/features/reader/presentation/view_models/reader_chrome_notifier.dart';
import 'package:hentai_library/features/reader/presentation/view_models/reader_navigation_intent.dart';
import 'package:hentai_library/features/reader/presentation/view_models/reader_prefetch_notifier.dart';
import 'package:hentai_library/features/reader/presentation/view_models/reader_series_navigation.dart';
import 'package:hentai_library/features/reader/presentation/view_models/read_session_providers.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reader_view_model.freezed.dart';
part 'reader_view_model.g.dart';
part 'reader_view_model_navigation.dart';
part 'reader_view_model_auto_play.dart';

/// 翻页越界切卷的二次确认方向（末页→下一卷 / 首页→上一卷）。
enum SeriesBoundaryPrompt { none, advance, retreat }

typedef ReaderViewModelKey = ({
  String comicId,
  bool incognito,
  bool startFromFirstPage,
});

ReaderViewModelKey readerViewModelKey(
  String comicId, {
  bool incognito = false,
  bool startFromFirstPage = false,
}) => (
  comicId: comicId,
  incognito: incognito,
  startFromFirstPage: startFromFirstPage,
);

@freezed
abstract class ReaderUiState with _$ReaderUiState {
  factory ReaderUiState({
    required ReaderComicRef comic,
    @Default(ReadingMode.paged) ReadingMode readingMode,
    @Default(false) bool showControls,
    @Default(1) int currentIndex,
    int? totalPagesOverride,
    @Default(SeriesBoundaryPrompt.none)
    SeriesBoundaryPrompt seriesBoundaryPrompt,
    @Default(false) bool autoPlayEnabled,
  }) = _ReaderUiState;

  ReaderUiState._();

  int get totalPages => totalPagesOverride ?? 0;
}

@riverpod
class ReaderViewModel extends _$ReaderViewModel
    with _ReaderViewModelNavigation, _ReaderViewModelAutoPlay {
  @override
  Future<ReaderUiState> build(ReaderViewModelKey key) async {
    final String id = key.comicId;
    final bool incognito = key.incognito;
    final bool startFromFirstPage = key.startFromFirstPage;
    final OpenedReadSession snapshot = await ref.watch(
      readerSessionOpenProvider(
        comicId: id,
        incognito: incognito,
        startFromFirstPage: startFromFirstPage,
      ).future,
    );
    final ReadingMode initialMode =
        (await _resolveInitialReadingPreferences()).readingMode;
    ref.listen(readingPreferencesProvider, (previous, next) {
      setReadingMode(next.readingMode);
    });
    final bool carryAutoPlay = ref
        .read(readerAutoPlayCarryProvider.notifier)
        .take();
    await ref
        .read(readSessionApplicationServiceProvider)
        .beginReadSession(
          comic: snapshot.comic,
          incognito: incognito,
          initialPageIndex: snapshot.resumePageIndex,
        );
    return ReaderUiState(
      comic: snapshot.comic,
      readingMode: initialMode,
      currentIndex: snapshot.resumePageIndex,
      totalPagesOverride: snapshot.totalPages > 0 ? snapshot.totalPages : null,
      autoPlayEnabled: carryAutoPlay && initialMode.supportsAutoPlay,
    );
  }

  /// 首帧偏好：已加载则直接解码；未加载时等待一次，避免阅读器先用默认档位打开。
  Future<ReadingPreferences> _resolveInitialReadingPreferences() async {
    if (ref.read(readingPreferencesRecordProvider) != null) {
      return ref.read(readingPreferencesProvider);
    }
    try {
      final AppSetting setting = await ref.read(appSettingsProvider.future);
      return ReadingPreferencesAcl.decode(readingPreferencesRecordOf(setting))
          .value;
    } catch (_) {
      return const ReadingPreferences.defaults();
    }
  }

  String get _comicId => (ref.$arg as ReaderViewModelKey).comicId;

  void toggleShowControls() {
    _updateDataState((s) => s.copyWith(showControls: !s.showControls));
  }

  void setShowControls(bool value) {
    _updateDataState((s) => s.copyWith(showControls: value));
  }

  void setReadingMode(ReadingMode value) {
    _updateDataState((ReaderUiState s) {
      if (s.readingMode == value) {
        return s;
      }
      final int remappedIndex = SpreadNavigation.remapPageForModeSwitch(
        fromMode: s.readingMode,
        toMode: value,
        currentPageIndex: s.currentIndex,
        totalPages: s.totalPages,
      );
      return s.copyWith(
        readingMode: value,
        currentIndex: remappedIndex,
        autoPlayEnabled: value.supportsAutoPlay ? s.autoPlayEnabled : false,
      );
    });
  }

  void setTotalPagesOverride(int? value) {
    _updateDataState((s) => s.copyWith(totalPagesOverride: value));
  }

  Future<ReaderReplaceReaderRouteIntent?> handleTapZone(
    ReaderTapZone zone, {
    ReaderNavContextData? navContext,
    OpenReaderArgs? session,
  }) async {
    final current = state.asData?.value;
    if (current == null) {
      return null;
    }
    if (current.showControls) {
      toggleShowControls();
      return null;
    }
    if (current.readingMode.isWebtoon) {
      toggleShowControls();
      return null;
    }
    return _handleHorizontalTap(zone, navContext: navContext, session: session);
  }

  Future<ReaderReplaceReaderRouteIntent?> _handleHorizontalTap(
    ReaderTapZone zone, {
    ReaderNavContextData? navContext,
    OpenReaderArgs? session,
  }) async {
    if (zone == ReaderTapZone.left) {
      return requestPrevPage(navContext: navContext, session: session);
    }
    if (zone == ReaderTapZone.right) {
      return requestNextPage(navContext: navContext, session: session);
    }
    toggleShowControls();
    return null;
  }

  Future<void> toggleFullscreen() async {
    await ref.read(readerChromeNotifierProvider.notifier).toggleFullscreen();
  }

  Future<void> pauseForeground() {
    return ref.read(readSessionApplicationServiceProvider).pauseForeground();
  }

  void resumeForeground() {
    ref.read(readSessionApplicationServiceProvider).resumeForeground();
  }

  Future<void> executeSaveProgress({
    required ReaderRouteContext routeContext,
  }) async {
    if (routeContext.incognito) {
      return;
    }
    final ReaderUiState? currentState = state.asData?.value;
    final ReadSessionApplicationService sessions = ref.read(
      readSessionApplicationServiceProvider,
    );
    if (currentState != null) {
      sessions.updatePage(currentState.currentIndex);
    }
    await sessions.flushProgress();
  }

  /// 结算会话并返回退出导航意图；由 View 执行 go_router。
  Future<ReaderExitIntent> prepareExitReader({
    required ReaderRouteContext routeContext,
    required bool canPop,
  }) async {
    await ref
        .read(readerChromeNotifierProvider.notifier)
        .exitFullscreenIfNeeded();
    final ReaderUiState? currentState = state.asData?.value;
    await ref
        .read(readSessionApplicationServiceProvider)
        .exitReadSession(
          comicId: _comicId,
          incognito: routeContext.incognito,
          currentPageIndex: currentState?.currentIndex,
        );
    ref.read(readerPrefetchNotifierProvider.notifier).clearComic(_comicId);
    final String? goLocation = resolveReaderExitNavigation(
      canPop: canPop,
      comicId: routeContext.comicId,
    );
    if (goLocation == null) {
      return const ReaderExitPopIntent();
    }
    return ReaderExitGoIntent(goLocation);
  }
}
