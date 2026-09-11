import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/data/adapters/reader_frb_mapper.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/reading/read_session_exceptions.dart';
import 'package:hentai_library/src/rust/api/init.dart';

void main() {
  test('mapResourceType covers every ResourceType wire token', () {
    expect(mapResourceType(ResourceType.dir), 'dir');
    expect(mapResourceType(ResourceType.zip), 'zip');
    expect(mapResourceType(ResourceType.cbz), 'cbz');
    expect(mapResourceType(ResourceType.epub), 'epub');
    expect(mapResourceType(ResourceType.cbr), 'cbr');
    expect(mapResourceType(ResourceType.rar), 'rar');
    expect(mapResourceType(ResourceType.cb7), 'cb7');
    expect(mapResourceType(ResourceType.sevenZ), 'sevenz');
    expect(mapResourceType(ResourceType.pdf), 'pdf');
  });

  test('throwReaderException wraps HentaiErrorDto as page load failure', () {
    const HentaiErrorDto error = HentaiErrorDto(
      code: 'Validation',
      message: 'broken archive',
      context: null,
    );

    expect(
      () => throwReaderException(error, comicId: 'c1', path: '/tmp/a.cbz'),
      throwsA(
        isA<ReadSessionPageLoadException>()
            .having(
              (ReadSessionPageLoadException e) => e.message,
              'message',
              contains('comicId=c1'),
            )
            .having(
              (ReadSessionPageLoadException e) => e.message,
              'message',
              contains('path=/tmp/a.cbz'),
            )
            .having(
              (ReadSessionPageLoadException e) => e.cause,
              'cause',
              same(error),
            ),
      ),
    );
  });

  test('throwReaderException defaults empty comicId and path', () {
    const HentaiErrorDto error = HentaiErrorDto(
      code: 'Validation',
      message: 'x',
      context: null,
    );

    expect(
      () => throwReaderException(error),
      throwsA(
        isA<ReadSessionPageLoadException>().having(
          (ReadSessionPageLoadException e) => e.message,
          'message',
          '加载漫画页面失败: comicId=, path=',
        ),
      ),
    );
  });
}
