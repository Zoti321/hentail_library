import 'package:flutter/foundation.dart';
import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/data/adapters/frb_error_mapper.dart';
import 'package:hentai_library/src/rust/api/init.dart';

/// FRB 流式 API 在绑定阶段通过 unawaited Future 抛出的错误兜底处理。
void handleUncaughtFrbZoneError(Object error, StackTrace stackTrace) {
  if (error is! HentaiErrorDto) {
    return;
  }
  if (isBenignFrbStreamClosed(error)) {
    return;
  }
  final AppException mapped = mapFrbError(error);
  FlutterError.presentError(
    FlutterErrorDetails(exception: mapped, stack: stackTrace),
  );
  debugPrint('未处理的 FRB 错误: ${frbErrorMessage(error)}\n$stackTrace');
}
