import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/read_session/data/mappers/reader_frb_mapper.dart';
import 'package:hentai_library/features/read_session/domain/read_session_exceptions.dart';
import 'package:hentai_library/src/rust/api/init.dart';

void main() {
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
            )
            .having(
              (ReadSessionPageLoadException e) => e.kind,
              'kind',
              ReadSessionFailureKind.loadFailed,
            ),
      ),
    );
  });

  test('mapReaderErrorKind covers resource and remote categories', () {
    expect(
      mapReaderErrorKind('ReaderNotFound'),
      ReadSessionFailureKind.resourceNotFound,
    );
    expect(
      mapReaderErrorKind('RemoteUnreachable'),
      ReadSessionFailureKind.remoteUnreachable,
    );
    expect(
      mapReaderErrorKind('RemoteTlsFailed'),
      ReadSessionFailureKind.remoteUnreachable,
    );
    expect(
      mapReaderErrorKind('RemoteAuthFailed'),
      ReadSessionFailureKind.remoteAuthFailed,
    );
    expect(mapReaderErrorKind('TimedOut'), ReadSessionFailureKind.timedOut);
    expect(
      mapReaderErrorKind('ComicTrashed'),
      ReadSessionFailureKind.comicTrashed,
    );
    expect(
      mapReaderErrorKind('ReaderInvalidContent'),
      ReadSessionFailureKind.invalidOrEmptyContent,
    );
  });

  test('throwReaderException maps TimedOut code to timedOut kind', () {
    const HentaiErrorDto error = HentaiErrorDto(
      code: 'TimedOut',
      message: 'deadline exceeded',
      context: null,
    );

    expect(
      () => throwReaderException(error, comicId: 'c1', path: '/tmp/a.cbz'),
      throwsA(
        isA<ReadSessionPageLoadException>().having(
          (ReadSessionPageLoadException e) => e.kind,
          'kind',
          ReadSessionFailureKind.timedOut,
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
