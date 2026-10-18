/// 应用业务/仓储层异常，供 UI 捕获并展示或重试。
class AppException implements Exception {
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  AppException(this.message, {this.cause, this.stackTrace});

  @override
  String toString() =>
      'AppException: $message${cause != null ? ' (cause: $cause)' : ''}';
}

/// 输入或参数无效（如无效目录路径、空表单）。
class ValidationException extends AppException {
  ValidationException(super.message, {super.cause, super.stackTrace});
}

/// 同步/扫描资源过程中的错误（如 IO、解析失败）。
class SyncException extends AppException {
  SyncException(super.message, {super.cause, super.stackTrace});
}

/// 请求的资源不存在（如漫画 id 不存在）。
class NotFoundException extends AppException {
  NotFoundException(super.message, {super.cause, super.stackTrace});
}

/// 与当前状态冲突（如并发更新、唯一约束冲突）。
class ConflictException extends AppException {
  ConflictException(super.message, {super.cause, super.stackTrace});
}
