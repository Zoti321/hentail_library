import 'package:dio/dio.dart';
import 'package:hentai_library/infrastructure/http/cancellable_dio_request.dart';
import 'package:hentai_library/shared/application/cancellation_token.dart';
import 'package:test/test.dart';

void main() {
  test('cancellation before a request reaches the HTTP adapter', () async {
    final CancellationToken cancellation = CancellationToken()..cancel('first');
    cancellation.cancel('second');
    await expectLater(
      runCancellableDioRequest<int>(cancellation, (token) async {
        expect(token.cancelError?.error, 'first');
        throw token.cancelError ?? StateError('Expected cancellation');
      }),
      throwsA(isA<OperationCancelledException>()),
    );
  });

  test(
    'cancelling an active request translates the transport exception',
    () async {
      final CancellationToken cancellation = CancellationToken();
      final Future<int> result = runCancellableDioRequest<int>(
        cancellation,
        (token) => token.whenCancel.then<int>((error) => throw error),
      );
      final Future<void> expectation = expectLater(
        result,
        throwsA(isA<OperationCancelledException>()),
      );
      cancellation.cancel();
      await expectation;
    },
  );

  test(
    'successful values and non-cancellation errors retain their identity',
    () async {
      expect(await runCancellableDioRequest<int>(null, (_) async => 7), 7);
      final DioException error = DioException(
        requestOptions: RequestOptions(path: '/dictionary'),
        type: DioExceptionType.connectionTimeout,
      );
      await expectLater(
        runCancellableDioRequest<int>(null, (_) async => throw error),
        throwsA(same(error)),
      );
    },
  );
}
