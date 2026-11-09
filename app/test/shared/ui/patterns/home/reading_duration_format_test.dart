import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/l10n/app_localizations_zh.dart';
import 'package:hentai_library/shared/ui/patterns/home/reading_duration_format.dart';

void main() {
  final AppLocalizationsZh l10n = AppLocalizationsZh();

  test('formatReadingDurationForDisplay covers zero / minutes / hours', () {
    expect(
      formatReadingDurationForDisplay(Duration.zero, l10n),
      l10n.homeReadingDurationZero,
    );
    expect(
      formatReadingDurationForDisplay(const Duration(minutes: 12), l10n),
      l10n.homeReadingDurationMinutes(12),
    );
    expect(
      formatReadingDurationForDisplay(const Duration(hours: 2), l10n),
      l10n.homeReadingDurationHours(2),
    );
    expect(
      formatReadingDurationForDisplay(
        const Duration(hours: 3, minutes: 20),
        l10n,
      ),
      l10n.homeReadingDurationHoursMinutes(3, 20),
    );
  });
}
