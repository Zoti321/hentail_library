import 'package:hentai_library/shared/application/errors/app_exception.dart';

/// 外部操作失败；不表示领域不变式被违反。
class FrbOperationException extends AppException {
  FrbOperationException(super.message, {super.cause, super.stackTrace});
}
