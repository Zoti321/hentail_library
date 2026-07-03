import 'dart:async';

import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/data/adapters/frb_error_mapper.dart';
import 'package:hentai_library/src/rust/api/init.dart';

Never _rethrowFrb(
  Object error,
  StackTrace stackTrace, {
  String? fallbackMessage,
}) {
  if (error is HentaiErrorDto) {
    Error.throwWithStackTrace(
      mapFrbError(
        error,
        fallbackMessage: fallbackMessage,
        stackTrace: stackTrace,
      ),
      stackTrace,
    );
  }
  Error.throwWithStackTrace(error, stackTrace);
}

/// 包装同步 FRB 调用，将 [HentaiErrorDto] 映射为 [AppException]。
T guardFrbSync<T>(T Function() call, {String? fallbackMessage}) {
  try {
    return call();
  } on HentaiErrorDto catch (error, stackTrace) {
    _rethrowFrb(error, stackTrace, fallbackMessage: fallbackMessage);
  }
}

/// 包装异步 FRB 调用，将 [HentaiErrorDto] 映射为 [AppException]。
Future<T> guardFrb<T>(
  Future<T> Function() call, {
  String? fallbackMessage,
}) async {
  try {
    return await call();
  } on HentaiErrorDto catch (error, stackTrace) {
    _rethrowFrb(error, stackTrace, fallbackMessage: fallbackMessage);
  }
}

/// 包装 FRB Stream，将流内 [HentaiErrorDto] 映射为 [AppException]。
Stream<T> guardFrbStream<T>(
  Stream<T> Function() create, {
  String? fallbackMessage,
}) {
  return create().handleError(
    (Object error, StackTrace stackTrace) {
      if (error is HentaiErrorDto && isBenignFrbStreamClosed(error)) {
        return;
      }
      _rethrowFrb(error, stackTrace, fallbackMessage: fallbackMessage);
    },
  );
}
