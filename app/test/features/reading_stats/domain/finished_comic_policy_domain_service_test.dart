import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/reading_stats/domain/finished_comic_policy_domain_service.dart';

void main() {
  group('FinishedComicPolicyDomainService.shouldMarkFinished', () {
    test('incognito never marks', () {
      expect(
        FinishedComicPolicyDomainService.shouldMarkFinished(
          incognito: true,
          pageIndex: 10,
          pageCount: 10,
        ),
        isFalse,
      );
    });

    test('zero pageCount never marks', () {
      expect(
        FinishedComicPolicyDomainService.shouldMarkFinished(
          incognito: false,
          pageIndex: 0,
          pageCount: 0,
        ),
        isFalse,
      );
    });

    test('last page marks finished', () {
      expect(
        FinishedComicPolicyDomainService.shouldMarkFinished(
          incognito: false,
          pageIndex: 12,
          pageCount: 12,
        ),
        isTrue,
      );
    });

    test('beyond last page still marks (sticky completion)', () {
      expect(
        FinishedComicPolicyDomainService.shouldMarkFinished(
          incognito: false,
          pageIndex: 15,
          pageCount: 12,
        ),
        isTrue,
      );
    });

    test('before last page does not mark', () {
      expect(
        FinishedComicPolicyDomainService.shouldMarkFinished(
          incognito: false,
          pageIndex: 11,
          pageCount: 12,
        ),
        isFalse,
      );
    });
  });
}
