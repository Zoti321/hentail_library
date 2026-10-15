import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/reading/read_session_exceptions.dart';
import 'package:hentai_library/src/rust/api/init.dart';

/// 将 FRB [HentaiErrorDto.code] 映射为 Read session 用户可见分类。
ReadSessionFailureKind mapReaderErrorKind(String code) {
  return switch (code) {
    'ReaderNotFound' => ReadSessionFailureKind.resourceNotFound,
    'RemoteUnreachable' ||
    'RemoteTlsFailed' => ReadSessionFailureKind.remoteUnreachable,
    'RemoteAuthFailed' => ReadSessionFailureKind.remoteAuthFailed,
    'TimedOut' => ReadSessionFailureKind.timedOut,
    'ReaderInvalidContent' ||
    'ReaderKindMismatch' ||
    'ReaderUnsupportedType' => ReadSessionFailureKind.invalidOrEmptyContent,
    _ => ReadSessionFailureKind.loadFailed,
  };
}

Never throwReaderException(
  HentaiErrorDto error, {
  ResourceType? resourceType,
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

String mapResourceType(ResourceType type) {
  return switch (type) {
    ResourceType.dir => 'dir',
    ResourceType.zip => 'zip',
    ResourceType.cbz => 'cbz',
    ResourceType.epub => 'epub',
    ResourceType.cbr => 'cbr',
    ResourceType.rar => 'rar',
    ResourceType.cb7 => 'cb7',
    ResourceType.sevenZ => 'sevenz',
    ResourceType.pdf => 'pdf',
  };
}
