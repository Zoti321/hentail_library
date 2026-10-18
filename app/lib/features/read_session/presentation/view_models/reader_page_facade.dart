import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/features/read_session/presentation/view_models/reader_controller.dart';
import 'package:hentai_library/features/read_session/presentation/view_models/reader_fullscreen_controller.dart';
import 'package:hentai_library/features/read_session/presentation/view_models/series_reader_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reader_page_facade.freezed.dart';
part 'reader_page_facade.g.dart';

/// 控制器状态投影：外壳仅依赖漫画与总页数（翻页索引不在此列）。
typedef _ReaderPageViewShell = ({Comic comic, int totalPages});

/// 阅读页外壳的稳定打开态字段（不含翻页索引 / chrome / 阅读模式）。
typedef ReaderPageShellData = ({
  Comic comic,
  int totalPages,
  ReadSessionContextData sessionContext,
});

/// 阅读页根节点唯一需要 watch 的聚合状态（ADR-0017：页面根仅 watch 一个 Facade provider）。
///
/// 叶子 widget 仍应通过 `readerControllerProvider(viewKey).select` 细粒度订阅，
/// 不要把 [ReaderPageFacadeState] 整体下发给翻页相关子树。
@freezed
abstract class ReaderPageFacadeState with _$ReaderPageFacadeState {
  factory ReaderPageFacadeState({
    required ReaderControllerKey viewKey,
    required AsyncValue<ReaderPageShellData> shellAsync,
    required bool readerFullscreen,
    required SeriesBoundaryPrompt seriesBoundaryPrompt,
  }) = _ReaderPageFacadeState;
}

/// 聚合阅读页外壳所需的控制器状态、会话上下文、全屏与切卷提示。
///
/// [comicId] 须已由调用方规范化（trim）。
@riverpod
ReaderPageFacadeState readerPageFacade(
  Ref ref, {
  required String comicId,
  bool incognito = false,
  bool startFromFirstPage = false,
}) {
  final ReaderControllerKey viewKey = readerControllerKey(
    comicId,
    incognito: incognito,
    startFromFirstPage: startFromFirstPage,
  );
  // 外壳只关心 comic + totalPages：翻页不得重建页面根。
  final AsyncValue<_ReaderPageViewShell> viewShellAsync = ref.watch(
    readerControllerProvider(viewKey).select((
      AsyncValue<ReaderState> asyncState,
    ) {
      if (asyncState.hasError) {
        return AsyncError<_ReaderPageViewShell>(
          asyncState.error!,
          asyncState.stackTrace!,
        );
      }
      final ReaderState? state = asyncState.asData?.value;
      if (state == null) {
        return const AsyncLoading<_ReaderPageViewShell>();
      }
      return AsyncData<_ReaderPageViewShell>((
        comic: state.comic,
        totalPages: state.totalPages,
      ));
    }),
  );
  final AsyncValue<ReadSessionContextData> sessionAsync = ref.watch(
    readSessionContextForReaderProvider(
      comicId: comicId,
      incognito: incognito,
      startFromFirstPage: startFromFirstPage,
    ),
  );
  final bool readerFullscreen = ref.watch(readerFullscreenControllerProvider);
  final SeriesBoundaryPrompt seriesBoundaryPrompt = ref.watch(
    readerControllerProvider(viewKey).select(
      (AsyncValue<ReaderState> asyncState) =>
          asyncState.asData?.value.seriesBoundaryPrompt ??
          SeriesBoundaryPrompt.none,
    ),
  );

  return ReaderPageFacadeState(
    viewKey: viewKey,
    shellAsync: _combineReaderShell(viewShellAsync, sessionAsync),
    readerFullscreen: readerFullscreen,
    seriesBoundaryPrompt: seriesBoundaryPrompt,
  );
}

AsyncValue<ReaderPageShellData> _combineReaderShell(
  AsyncValue<_ReaderPageViewShell> viewShell,
  AsyncValue<ReadSessionContextData> session,
) {
  if (viewShell.hasError) {
    return AsyncError(viewShell.error!, viewShell.stackTrace!);
  }
  if (session.hasError) {
    return AsyncError(session.error!, session.stackTrace!);
  }
  final _ReaderPageViewShell? view = viewShell.asData?.value;
  final ReadSessionContextData? sessionData = session.asData?.value;
  if (view == null || sessionData == null) {
    return const AsyncLoading<ReaderPageShellData>();
  }
  return AsyncData<ReaderPageShellData>((
    comic: view.comic,
    totalPages: view.totalPages,
    sessionContext: sessionData,
  ));
}
