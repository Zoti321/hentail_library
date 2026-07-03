import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/data/adapters/frb_error_mapper.dart';
import 'package:hentai_library/src/rust/api/init.dart';
import 'package:test/test.dart';

void main() {
  test('mapFrbError maps validation to SyncException with message', () {
    const error = HentaiErrorDto(
      code: 'Validation',
      message: '目录扫描失败: D:/missing',
      context: null,
    );

    final AppException mapped = mapFrbError(error);

    expect(mapped, isA<SyncException>());
    expect(mapped.message, '目录扫描失败: D:/missing');
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
