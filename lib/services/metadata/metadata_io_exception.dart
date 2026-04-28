import 'package:hentai_library/core/errors/app_exception.dart';

class MetadataIoFormatException extends AppException {
  MetadataIoFormatException(super.message, {super.cause, super.stackTrace});
}

class MetadataImportException extends AppException {
  MetadataImportException(super.message, {super.cause, super.stackTrace});
}

class MetadataExportException extends AppException {
  MetadataExportException(super.message, {super.cause, super.stackTrace});
}
