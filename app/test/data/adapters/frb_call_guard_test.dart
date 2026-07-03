import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/data/adapters/frb_call_guard.dart';
import 'package:hentai_library/src/rust/api/init.dart';
import 'package:test/test.dart';

void main() {
  test('guardFrbSync maps HentaiErrorDto to AppException', () {
    expect(
      () => guardFrbSync(
        () => throw const HentaiErrorDto(
          code: 'DbInitFailed',
          message: 'init_db 尚未调用',
          context: null,
        ),
        fallbackMessage: '数据库未就绪',
      ),
      throwsA(
        isA<AppException>().having(
          (AppException e) => e.message,
          'message',
          'init_db 尚未调用',
        ),
      ),
    );
  });

  test('guardFrbStream maps stream errors to AppException', () async {
    final Stream<int> stream = guardFrbStream(
      () => Stream<int>.error(
        const HentaiErrorDto(
          code: 'DbQueryFailed',
          message: 'no such table',
          context: null,
        ),
      ),
      fallbackMessage: '查询失败',
    );

    await expectLater(
      stream.first,
      throwsA(
        isA<SyncException>().having(
          (SyncException e) => e.message,
          'message',
          'no such table',
        ),
      ),
    );
  });

  test('guardFrbStream ignores benign stream closed errors', () async {
    final List<int> values = await guardFrbStream(
      () => Stream<int>.error(
        const HentaiErrorDto(
          code: 'Validation',
          message: 'stream closed',
          context: null,
        ),
      ),
      fallbackMessage: '查询失败',
    ).toList();

    expect(values, isEmpty);
  });
}
