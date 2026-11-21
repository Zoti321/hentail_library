import 'package:hentai_library/features/reader/domain/read_session_capabilities.dart';
import 'package:hentai_library/features/reader/domain/read_session_subject.dart';
import 'package:hentai_library/features/reader/domain/reader_comic_ref.dart';
import 'package:hentai_library/features/reader/presentation/view_models/series_reader_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 阅读页外壳的稳定打开态字段（不含翻页索引 / chrome / 阅读模式）。
typedef ReaderPageShellData = ({
  ReadSessionSubject subject,
  ReaderComicRef? comic,
  ReadSessionCapabilities capabilities,
  int totalPages,
  ReadSessionContextData sessionContext,
});

typedef ReaderPageViewShell = ({
  ReadSessionSubject subject,
  ReaderComicRef? comic,
  ReadSessionCapabilities capabilities,
  int totalPages,
});

/// 仅由 ViewModel 外壳决定就绪；系列上下文渐进填充，loading/error 不挡首屏。
AsyncValue<ReaderPageShellData> readerPageShellFromView(
  AsyncValue<ReaderPageViewShell> viewShell, {
  required ReadSessionContextData sessionContext,
}) {
  if (viewShell.hasError) {
    return AsyncError<ReaderPageShellData>(
      viewShell.error!,
      viewShell.stackTrace!,
    );
  }
  final ReaderPageViewShell? view = viewShell.asData?.value;
  if (view == null) {
    return const AsyncLoading<ReaderPageShellData>();
  }
  return AsyncData<ReaderPageShellData>((
    subject: view.subject,
    comic: view.comic,
    capabilities: view.capabilities,
    totalPages: view.totalPages,
    sessionContext: sessionContext,
  ));
}

/// 合并 ViewModel 外壳与系列会话上下文。
///
/// 系列侧 loading/error 回落为空上下文，不挡就绪壳；仅 ViewModel error/loading
/// 决定整体同态。
AsyncValue<ReaderPageShellData> combineReaderPageShell(
  AsyncValue<ReaderPageViewShell> viewShell,
  AsyncValue<ReadSessionContextData> session, {
  required String sessionKey,
}) {
  final ReadSessionContextData sessionContext =
      session.asData?.value ?? emptyReadSessionContextData(sessionKey);
  return readerPageShellFromView(viewShell, sessionContext: sessionContext);
}
