import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/app_settings/public/reading_preferences_schema.dart';
import 'package:hentai_library/features/reader/domain/auto_play_mode.dart';
import 'package:hentai_library/features/reader/domain/reading_mode.dart';
import 'package:hentai_library/features/reader/domain/reading_preferences.dart';
import 'package:hentai_library/features/reader/public/reading_preferences_acl.dart';

/// 阅读偏好防腐层形状门禁（ADR-0046）。
///
/// 锁定三件事：
/// 1. `decode` 是全函数——任意输入都产出合法值，绝不抛异常；
/// 2. `encode` ↔ `decode` 在全部合法值域上互为逆（双射）；
/// 3. `app_settings` schema 的 id 白名单、默认值与 `reader` 枚举完全一致。
void main() {
  ReadingPreferencesRecord recordOf({
    String readingModeId = ReadingPreferenceSchema.defaultReadingModeId,
    String webtoonZoomModeId = ReadingPreferenceSchema.defaultWebtoonZoomModeId,
    int webtoonMarginPercent =
        ReadingPreferenceSchema.defaultWebtoonMarginPercent,
    String autoPlayModeId = ReadingPreferenceSchema.defaultAutoPlayModeId,
    int autoPlayIntervalSeconds =
        ReadingPreferenceSchema.defaultAutoPlayIntervalSeconds,
  }) => (
    readingModeId: readingModeId,
    webtoonZoomModeId: webtoonZoomModeId,
    webtoonMarginPercent: webtoonMarginPercent,
    autoPlayModeId: autoPlayModeId,
    autoPlayIntervalSeconds: autoPlayIntervalSeconds,
  );

  group('schema 与领域枚举一致', () {
    test('readingMode id 白名单与默认值', () {
      expect(ReadingPreferenceSchema.readingModeIds, <String>{
        for (final ReadingMode mode in ReadingMode.values)
          ReadingPreferencesAcl.encode(
            ReadingPreferences.defaults().copyWith(readingMode: mode),
          ).readingModeId,
      });
      expect(
        ReadingPreferencesAcl.encode(ReadingPreferences.defaults())
            .readingModeId,
        ReadingPreferenceSchema.defaultReadingModeId,
      );
      expect(
        ReadingPreferencesAcl.encode(const ReadingPreferences.defaults())
            .readingModeId,
        ReadingPreferenceSchema.defaultReadingModeId,
      );
    });

    test('webtoonZoomMode id 白名单与默认值', () {
      expect(ReadingPreferenceSchema.webtoonZoomModeIds, <String>{
        for (final WebtoonZoomMode mode in WebtoonZoomMode.values)
          ReadingPreferencesAcl.encode(
            ReadingPreferences.defaults().copyWith(webtoonZoomMode: mode),
          ).webtoonZoomModeId,
      });
      expect(
        ReadingPreferencesAcl.encode(const ReadingPreferences.defaults())
            .webtoonZoomModeId,
        ReadingPreferenceSchema.defaultWebtoonZoomModeId,
      );
    });

    test('autoPlayMode id 白名单与默认值', () {
      expect(ReadingPreferenceSchema.autoPlayModeIds, <String>{
        for (final AutoPlayMode mode in AutoPlayMode.values)
          ReadingPreferencesAcl.encode(
            ReadingPreferences.defaults().copyWith(autoPlayMode: mode),
          ).autoPlayModeId,
      });
      expect(
        ReadingPreferencesAcl.encode(const ReadingPreferences.defaults())
            .autoPlayModeId,
        ReadingPreferenceSchema.defaultAutoPlayModeId,
      );
    });

    test('数值默认值与 reader 常量一致', () {
      const ReadingPreferences defaults = ReadingPreferences.defaults();
      expect(
        defaults.webtoonMarginPercent,
        ReadingPreferenceSchema.defaultWebtoonMarginPercent,
      );
      expect(
        defaults.autoPlayIntervalSeconds,
        ReadingPreferenceSchema.defaultAutoPlayIntervalSeconds,
      );
    });
  });

  group('encode / decode 双射', () {
    test('全部合法组合 round-trip 恒等', () {
      for (final ReadingMode readingMode in ReadingMode.values) {
        for (final WebtoonZoomMode zoom in WebtoonZoomMode.values) {
          for (final AutoPlayMode autoPlay in AutoPlayMode.values) {
            final ReadingPreferences value = ReadingPreferences(
              readingMode: readingMode,
              webtoonZoomMode: zoom,
              webtoonMarginPercent: 35,
              autoPlayMode: autoPlay,
              autoPlayIntervalSeconds: 12,
            );
            final DecodedReadingPreferences decoded =
                ReadingPreferencesAcl.decode(
                  ReadingPreferencesAcl.encode(value),
                );
            expect(decoded.value, value);
            expect(decoded.unknownIds, isEmpty);
          }
        }
      }
    });
  });

  group('decode 是全函数', () {
    test('未知 id 全部回退默认值并逐个上报', () {
      final DecodedReadingPreferences decoded = ReadingPreferencesAcl.decode(
        recordOf(
          readingModeId: 'continuousVertical',
          webtoonZoomModeId: 'nope',
          autoPlayModeId: 'nope',
        ),
      );
      expect(decoded.value.readingMode, kDefaultReadingMode);
      expect(decoded.value.webtoonZoomMode, kDefaultWebtoonZoomMode);
      expect(decoded.value.autoPlayMode, kDefaultAutoPlayMode);
      expect(decoded.unknownIds, <String>[
        'continuousVertical',
        'nope',
        'nope',
      ]);
    });

    test('空字符串与越界数值也收敛到合法值', () {
      final DecodedReadingPreferences decoded = ReadingPreferencesAcl.decode(
        recordOf(
          readingModeId: '',
          webtoonMarginPercent: -999,
          autoPlayIntervalSeconds: 9999,
        ),
      );
      expect(decoded.value.readingMode, kDefaultReadingMode);
      expect(decoded.value.webtoonMarginPercent, 0);
      expect(
        decoded.value.autoPlayIntervalSeconds,
        ReadingPreferenceSchema.maxAutoPlayIntervalSeconds,
      );
      expect(decoded.unknownIds, <String>['']);
    });
  });
}
