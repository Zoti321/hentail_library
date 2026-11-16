import 'package:hentai_library/l10n/app_localizations_zh.dart';
import 'package:hentai_library/features/series/presentation/l10n/series_l10n.dart';
import 'package:test/test.dart';

void main() {
  group('Series volume labels', () {
    test('volume count label uses l10n', () {
      final l10n = AppLocalizationsZh();
      expect(l10n.seriesVolumeCountLabel(3), '3 本');
      expect(
        l10n.seriesVolumeProgressLabel(current: 3, total: 12),
        '3 / 共 12 本',
      );
      expect(l10n.seriesVolumeProgressLabel(current: 3, total: null), isNull);
    });
  });
}
