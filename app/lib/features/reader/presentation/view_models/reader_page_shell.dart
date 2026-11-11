import 'package:hentai_library/features/reader/domain/reader_comic_ref.dart';
import 'package:hentai_library/features/reader/presentation/view_models/series_reader_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 阅读页外壳的稳定打开态字段（不含翻页索引 / chrome / 阅读模式）。
typedef ReaderPageShellData = ({
  ReaderComicRef comic,
  int totalPages,
  ReadSessionContextData sessionContext,
});

typedef ReaderPageViewShell = ({ReaderComicRef comic, int totalPages});

/// 合并 ViewModel 外壳与系列会话上下文；任一侧 error/loading 则整体同态。
AsyncValue<ReaderPageShellData> combineReaderPageShell(
  AsyncValue<ReaderPageViewShell> viewShell,
  AsyncValue<ReadSessionContextData> session,
) {
  if (viewShell.hasError) {
    return AsyncError<ReaderPageShellData>(
      viewShell.error!,
      viewShell.stackTrace!,
    );
  }
  if (session.hasError) {
    return AsyncError<ReaderPageShellData>(session.error!, session.stackTrace!);
  }
  final ReaderPageViewShell? view = viewShell.asData?.value;
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
