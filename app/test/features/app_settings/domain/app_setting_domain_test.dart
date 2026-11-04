import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/app_settings/domain/app_setting.dart';
import 'package:hentai_library/features/read_session/public/reading_preference_types.dart';

void main() {
  test('withNormalizedReaderPreferences clamps reader interval and margin', () {
    final AppSetting raw = AppSetting(
      webtoonMarginPercent: 23,
      readerAutoPlayIntervalSeconds: 999,
    );
    final AppSetting normalized = raw.withNormalizedReaderPreferences();
    expect(normalized.webtoonMarginPercent, 25);
    expect(normalized.readerAutoPlayIntervalSeconds, 60);
  });

  test('shouldPromptForUpdate respects autoUpdate and dismissed version', () {
    final AppSetting settings = AppSetting(
      autoUpdate: true,
      dismissedUpdateVersion: '1.0.0',
    );
    expect(settings.shouldPromptForUpdate('1.0.0'), isFalse);
    expect(settings.shouldPromptForUpdate('1.0.1'), isTrue);
    expect(settings.copyWith(autoUpdate: false).shouldPromptForUpdate('1.0.1'), isFalse);
  });
}
