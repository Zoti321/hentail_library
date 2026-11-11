import 'package:hentai_library/features/reader/domain/read_session.dart';
import 'package:hentai_library/features/reader/domain/read_session_exceptions.dart';
import 'package:hentai_library/features/reader/domain/reader_comic_ref.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:test/test.dart';

ReaderComicRef _comic({int pageCount = 10}) {
  return ReaderComicRef(
    comicId: 'c1',
    path: '/tmp/c1',
    resourceType: ResourceType.zip,
    title: 'T',
    pageCount: pageCount,
  );
}

void main() {
  group('ReadSession', () {
    test('clamps initial page to pageCount', () {
      final ReadSession session = ReadSession(
        comic: _comic(pageCount: 5),
        initialPageIndex: 99,
        foregroundStartedAt: DateTime.utc(2026, 1, 1),
      );
      expect(session.pageIndex, 5);
    });

    test('updatePage rejects non-positive index', () {
      final ReadSession session = ReadSession(
        comic: _comic(),
        initialPageIndex: 1,
        foregroundStartedAt: DateTime.utc(2026, 1, 1),
      );
      expect(() => session.updatePage(0), throwsA(isA<ReadSessionException>()));
    });

    test('foreground accrual pauses and takes elapsed', () {
      final DateTime t0 = DateTime.utc(2026, 1, 1, 12);
      final ReadSession session = ReadSession(
        comic: _comic(),
        initialPageIndex: 2,
        foregroundStartedAt: t0,
      );
      session.pauseForeground(t0.add(const Duration(seconds: 5)));
      session.resumeForeground(t0.add(const Duration(seconds: 10)));
      final Duration elapsed = session.takeForegroundElapsed(
        t0.add(const Duration(seconds: 13)),
      );
      expect(elapsed, const Duration(seconds: 8));
      expect(
        session.takeForegroundElapsed(t0.add(const Duration(seconds: 20))),
        Duration.zero,
      );
    });
  });
}
