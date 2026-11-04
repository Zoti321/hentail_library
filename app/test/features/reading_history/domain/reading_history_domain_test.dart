import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/reading_history/domain/reading_history.dart';
import 'package:hentai_library/features/reading_history/domain/reading_history_domain_exception.dart';
import 'package:hentai_library/features/reading_history/domain/reading_history_search_spec.dart';
import 'package:hentai_library/shared/domain/exceptions/domain_rule_violation.dart';

void main() {
  group('ReadingHistory.recordSessionProgress', () {
    final DateTime when = DateTime.utc(2026, 1, 2);

    test('builds snapshot and trims identifiers', () {
      final record = ReadingHistory.recordSessionProgress(
        comicId: '  c1  ',
        title: '  Title  ',
        lastReadTime: when,
        pageIndex: 2,
        pageCount: 10,
      );
      final ReadingHistory snapshot = record.snapshot;
      expect(snapshot.comicId, 'c1');
      expect(snapshot.title, 'Title');
      expect(snapshot.pageIndex, 2);
      expect(snapshot.pageCount, 10);
      expect(snapshot.readProgressRatio, closeTo(0.2, 0.001));
    });

    test('rejects empty comic id', () {
      expect(
        () => ReadingHistory.recordSessionProgress(
          comicId: '   ',
          title: 'T',
          lastReadTime: when,
          pageIndex: 1,
        ),
        throwsA(
          isA<ReadingHistoryDomainException>().having(
            (ReadingHistoryDomainException e) => e.code,
            'code',
            'reading_history.empty_comic_id',
          ),
        ),
      );
    });

    test('rejects non-positive page index', () {
      expect(
        () => ReadingHistory.recordSessionProgress(
          comicId: 'c1',
          title: 'T',
          lastReadTime: when,
          pageIndex: 0,
        ),
        throwsA(isA<DomainRuleViolation>()),
      );
    });

    test('rejects page index beyond page count when count known', () {
      expect(
        () => ReadingHistory.recordSessionProgress(
          comicId: 'c1',
          title: 'T',
          lastReadTime: when,
          pageIndex: 11,
          pageCount: 10,
        ),
        throwsA(
          isA<ReadingHistoryDomainException>().having(
            (ReadingHistoryDomainException e) => e.code,
            'code',
            'reading_history.page_index_exceeds_count',
          ),
        ),
      );
    });
  });

  group('normalizeReadingHistorySearchKeyword', () {
    test('blank becomes null', () {
      expect(normalizeReadingHistorySearchKeyword(null), isNull);
      expect(normalizeReadingHistorySearchKeyword(''), isNull);
      expect(normalizeReadingHistorySearchKeyword('   '), isNull);
    });

    test('trims non-empty keyword', () {
      expect(normalizeReadingHistorySearchKeyword('  abc '), 'abc');
    });
  });
}
