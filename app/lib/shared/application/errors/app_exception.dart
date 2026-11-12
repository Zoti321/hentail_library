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
