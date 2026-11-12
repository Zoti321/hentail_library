import 'dart:async';

import 'package:dio/dio.dart';
import 'package:hentai_library/shared/application/cancellation_token.dart';

Future<T> runCancellableDioRequest<T>(
  CancellationToken? cancellation,
  Future<T> Function(CancelToken token) request,
) async {
  final CancelToken token = CancelToken();
  if (cancellation != null) {
    if (cancellation.isCancelled) {
      token.cancel(cancellation.reason);
    } else {
      unawaited(_forwardCancellation(cancellation, token));
    }
  }
  try {
    return await request(token);
  } on DioException catch (error, stackTrace) {
    if (CancelToken.isCancel(error)) {
      Error.throwWithStackTrace(
        const OperationCancelledException(),
        stackTrace,
      );
    }
    rethrow;
  }
}

Future<void> _forwardCancellation(
  CancellationToken source,
  CancelToken target,
) async {
  target.cancel(await source.whenCancelled);
}
