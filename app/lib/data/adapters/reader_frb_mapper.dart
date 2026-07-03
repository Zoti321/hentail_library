import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/reading/read_session_exceptions.dart';
import 'package:hentai_library/src/rust/api/init.dart';

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
