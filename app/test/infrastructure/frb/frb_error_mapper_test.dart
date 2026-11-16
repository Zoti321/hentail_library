import 'package:hentai_library/infrastructure/frb/frb_operation_exception.dart';
import 'package:hentai_library/shared/application/errors/app_exception.dart';
import 'package:hentai_library/infrastructure/frb/frb_error_mapper.dart';
import 'package:hentai_library/src/rust/api/init.dart';
import 'package:test/test.dart';

void main() {
  test('mapFrbError maps validation to FrbOperationException with message', () {
    const error = HentaiErrorDto(
      code: 'Validation',
      message: '目录扫描失败: D:/missing',
      context: null,
    );

    final stack = StackTrace.fromString('original FRB stack');
    final AppException mapped = mapFrbError(error, stackTrace: stack);

    expect(mapped, isA<FrbOperationException>());
    expect(mapped.message, '目录扫描失败: D:/missing');
    expect(mapped.cause, same(error));
    expect(mapped.stackTrace, same(stack));
  });

  test('frbErrorMessage prefers message and context', () {
    const error = HentaiErrorDto(
      code: 'DbQueryFailed',
      message: 'too many SQL variables',
      context: 'DELETE FROM comics',
    );

    expect(
      frbErrorMessage(error),
      'too many SQL variables (DELETE FROM comics)',
    );
  });

  test('isBenignFrbStreamClosed detects cancelled watch streams', () {
    const error = HentaiErrorDto(
      code: 'Validation',
      message: 'stream closed',
      context: null,
    );

    expect(isBenignFrbStreamClosed(error), isTrue);
  });
}
