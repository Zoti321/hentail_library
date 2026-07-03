import 'package:hentai_library/data/services/comic/read_resource_get/core/comic_read_resource_exception.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/src/rust/api/init.dart';

Never throwReaderException(
  HentaiErrorDto error, {
  ResourceType? resourceType,
  String? path,
}) {
  final code = error.code;
  final message = error.message;
  if (code.contains('ReaderNotFound')) {
    throw ComicReadResourceNotFoundException(path: path ?? message);
  }
  if (code.contains('ReaderKindMismatch')) {
    throw ComicReadResourceKindMismatchException(
      path: path ?? '',
      expectedType: resourceType ?? ResourceType.dir,
      detail: message,
    );
  }
  if (code.contains('ReaderUnsupportedType')) {
    throw ComicReadResourceUnsupportedTypeException(
      type: resourceType ?? ResourceType.rar,
    );
  }
  if (code.contains('ReaderInvalidContent')) {
    throw ComicReadResourceInvalidContentException(message: message);
  }
  throw ComicReadResourceInvalidContentException(message: message);
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
