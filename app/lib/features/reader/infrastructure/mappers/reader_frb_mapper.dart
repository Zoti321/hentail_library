import 'package:hentai_library/features/reader/application/read_session_page_load_exception.dart';
import 'package:hentai_library/src/rust/api/init.dart';

/// 将 FRB [HentaiErrorDto.code] 映射为 Read session 用户可见分类。
ReadSessionFailureKind mapReaderErrorKind(String code) {
  return switch (code) {
    'ReaderNotFound' => ReadSessionFailureKind.resourceNotFound,
    'RemoteUnreachable' ||
    'RemoteTlsFailed' => ReadSessionFailureKind.remoteUnreachable,
    'RemoteAuthFailed' => ReadSessionFailureKind.remoteAuthFailed,
    'TimedOut' => ReadSessionFailureKind.timedOut,
    'ComicTrashed' => ReadSessionFailureKind.comicTrashed,
    'ReaderInvalidContent' ||
    'ReaderKindMismatch' ||
    'ReaderUnsupportedType' => ReadSessionFailureKind.invalidOrEmptyContent,
    _ => ReadSessionFailureKind.loadFailed,
  };
}

Never throwReaderException(
  HentaiErrorDto error, {
  String? path,
  String? comicId,
}) {
  throw ReadSessionPageLoadException.loadFailed(
    comicId: comicId ?? '',
    path: path ?? '',
    cause: error,
    kind: mapReaderErrorKind(error.code),
  );
}
