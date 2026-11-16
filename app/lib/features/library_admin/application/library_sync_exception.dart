import 'package:hentai_library/shared/application/errors/app_exception.dart';

/// Library sync 进度流报告的失败，保留面向用户的错误与原始原因。
class LibrarySyncException extends AppException {
  LibrarySyncException(super.message, {super.cause, super.stackTrace});
}
