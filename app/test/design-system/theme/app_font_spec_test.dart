import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/app_settings/presentation/mappers/app_font_preference_mapper.dart';
import 'package:hentai_library/features/app_settings/domain/app_setting.dart';
import 'package:hentai_library/design-system/design_system.dart';

void main() {
  group('appFontSpecForId', () {
    test('defaults unknown ids to MiSans with CJK fallbacks', () {
      final AppFontSpec spec = appFontSpecForId('unknown');
      expect(spec.family, kAppFontFamilyMiSans);
      expect(spec.fallbacks, <String>[
        kAppFontFamilyNotoSansSc,
        kAppFontFamilyNotoSans,
        kAppFontFamilyNotoSansJp,
      ]);
    });

    test('maps Noto Sans with SC/JP i18n fallbacks', () {
      final AppFontSpec spec = appFontSpecForId('notoSans');
      expect(spec.family, kAppFontFamilyNotoSans);
      expect(spec.fallbacks, kAppFontFamilyNotoCjkFallbacks);
    });

    test('maps legacy SC/JP preference ids onto Noto Sans', () {
      expect(appFontSpecForId('notoSansSc').family, kAppFontFamilyNotoSans);
      expect(appFontSpecForId('notoSansJp').family, kAppFontFamilyNotoSans);
    });
  });

  group('appFontSpecFor', () {
    test('matches preference enum to bundled families', () {
      expect(
        appFontSpecFor(AppFontPreference.notoSans).family,
        kAppFontFamilyNotoSans,
      );
      expect(appFontSpecFor(AppFontPreference.miSans).family, kAppFontFamily);
    });
  });

  group('assembleAppTheme font', () {
    test('writes selected family onto Material and M3E themes', () {
      final AppFontSpec font = appFontSpecFor(AppFontPreference.notoSans);
      final AssembledAppTheme assembled = assembleAppTheme(
        Brightness.light,
        font: font,
      );
      expect(
        assembled.material.textTheme.bodyLarge?.fontFamily,
        kAppFontFamilyNotoSans,
      );
      expect(
        assembled.material.textTheme.bodyLarge?.fontFamilyFallback,
        font.fallbacks,
      );
      expect(
        assembled.m3e.typeScale.bodyLarge.fontFamily,
        kAppFontFamilyNotoSans,
      );
    });
  });
}
