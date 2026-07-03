import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/src/rust/api/init.dart';

/// 将 Rust FRB 结构化错误映射为 Dart [AppException]。
AppException mapFrbError(
  HentaiErrorDto error, {
  String? fallbackMessage,
  StackTrace? stackTrace,
}) {
  final String detail = _formatDetail(error);
  final String message = error.message.trim().isNotEmpty
      ? error.message.trim()
      : (fallbackMessage ?? '操作失败');

  return switch (error.code) {
    'Validation' => SyncException(detail.isEmpty ? message : detail,
        cause: error, stackTrace: stackTrace),
    'DbInitFailed' => AppException(
        detail.isEmpty ? '数据库未初始化' : detail,
        cause: error,
        stackTrace: stackTrace,
      ),
    'DbQueryFailed' => SyncException(
        detail.isEmpty ? '数据库操作失败' : detail,
        cause: error,
        stackTrace: stackTrace,
      ),
    _ => AppException(
        detail.isEmpty ? message : detail,
        cause: error,
        stackTrace: stackTrace,
      ),
  };
}

String frbErrorMessage(HentaiErrorDto error, {String? fallbackMessage}) {
  final String detail = _formatDetail(error);
  if (detail.isNotEmpty) {
    return detail;
  }
  if (error.message.trim().isNotEmpty) {
    return error.message.trim();
  }
  return fallbackMessage ?? '操作失败';
}

/// Dart 侧取消 Stream 订阅后，Rust 会向已关闭 sink 写入；这是正常生命周期。
bool isBenignFrbStreamClosed(HentaiErrorDto error) {
  return error.code == 'Validation' && error.message.trim() == 'stream closed';
}

String _formatDetail(HentaiErrorDto error) {
  final String message = error.message.trim();
  final String? context = error.context?.trim();
  if (message.isEmpty && (context == null || context.isEmpty)) {
    return '';
  }
  if (context == null || context.isEmpty) {
    return message;
  }
  if (message.isEmpty) {
    return context;
  }
  return '$message ($context)';
}
