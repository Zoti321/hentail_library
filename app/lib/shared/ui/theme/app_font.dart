import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Bundled UI font family names ([pubspec.yaml] `flutter.fonts`).
const String kAppFontFamilyMiSans = 'MI_Sans_Regular';
const String kAppFontFamilyNotoSans = 'NotoSans';
const String kAppFontFamilyNotoSansSc = 'NotoSansSC';
const String kAppFontFamilyNotoSansJp = 'NotoSansJP';

/// Default UI font（与历史硬编码 [kAppFontFamily] 对齐）。
const String kAppFontFamily = kAppFontFamilyMiSans;

/// CJK language variants bundled for i18n fallback（非设置可选项）。
const List<String> kAppFontFamilyNotoCjkFallbacks = <String>[
  kAppFontFamilyNotoSansSc,
  kAppFontFamilyNotoSansJp,
];

/// Active UI font from Material / M3E text styles（overlays that lost family）.
String appFontFamilyOf(BuildContext context) {
  final String? fromTextTheme = Theme.of(context)
      .textTheme
      .bodyMedium
      ?.fontFamily;
  if (fromTextTheme != null && fromTextTheme.isNotEmpty) {
    return fromTextTheme;
  }
  final M3EThemeData? m3e = M3ETheme.maybeOf(context);
  final String? fromM3e = m3e?.typeScale.bodyLarge.fontFamily;
  if (fromM3e != null && fromM3e.isNotEmpty) {
    return fromM3e;
  }
  return kAppFontFamily;
}

/// Resolved primary family + fallbacks for one user font preference.
final class AppFontSpec {
  const AppFontSpec({required this.family, this.fallbacks = const <String>[]});

  final String family;
  final List<String> fallbacks;
}

/// Specs keyed by settings JSON ids (`miSans` / `notoSans`).
///
/// Legacy `notoSansSc` / `notoSansJp` map to Noto Sans（CJK 仍走 fallback）。
AppFontSpec appFontSpecForId(String id) {
  return switch (id) {
    'notoSans' || 'notoSansSc' || 'notoSansJp' => const AppFontSpec(
      family: kAppFontFamilyNotoSans,
      fallbacks: kAppFontFamilyNotoCjkFallbacks,
    ),
    'miSans' || _ => const AppFontSpec(
      family: kAppFontFamilyMiSans,
      fallbacks: <String>[
        kAppFontFamilyNotoSansSc,
        kAppFontFamilyNotoSans,
        kAppFontFamilyNotoSansJp,
      ],
    ),
  };
}
