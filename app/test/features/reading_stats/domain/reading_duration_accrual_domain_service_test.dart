import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/reading_stats/domain/reading_duration_accrual_domain_service.dart';

void main() {
  group('ReadingDurationAccrualDomainService.accruedDuration', () {
    test('incognito yields null', () {
      expect(
        ReadingDurationAccrualDomainService.accruedDuration(
          incognito: true,
          foregroundElapsed: const Duration(seconds: 30),
        ),
        isNull,
      );
    });

    test('under 10 seconds yields null', () {
      expect(
        ReadingDurationAccrualDomainService.accruedDuration(
          incognito: false,
          foregroundElapsed: const Duration(seconds: 9),
        ),
        isNull,
      );
    });

    test('exactly 10 seconds credits full elapsed', () {
      expect(
        ReadingDurationAccrualDomainService.accruedDuration(
          incognito: false,
          foregroundElapsed: const Duration(seconds: 10),
        ),
        const Duration(seconds: 10),
      );
    });

    test('over 10 seconds credits entire session including first 10s', () {
      expect(
        ReadingDurationAccrualDomainService.accruedDuration(
          incognito: false,
          foregroundElapsed: const Duration(seconds: 65),
        ),
        const Duration(seconds: 65),
      );
    });
  });
}
