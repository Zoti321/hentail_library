import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/theme/app_m3e_theme.dart';

/// 已知固定配色 id（与 `AppColorSchemePreference` JSON 值对齐）。
const Set<String> kKnownColorSchemeIds = <String>{
  'brand',
  'teal',
  'cyan',
  'blue',
  'indigo',
  'deepPurple',
  'violet',
  'pink',
  'sakura',
  'yellow',
  'orange',
  'deepOrange',
  'green',
};

/// Seed for [buildAppTheme] / [buildAppM3eThemeData] 的 `colorSchemeId`。
///
/// `brand` 定稿为紫罗兰（[kBrandSeedColor]），与偏好 id `violet` 同色。
/// 其余为适合 M3 fidelity 的饱和种子（Material 600 档或传统色参考），
/// 展示名见 l10n（青瓷色 / 矢车菊色等）。
Color colorSchemeSeedForId(String colorSchemeId) {
  assert(
    kKnownColorSchemeIds.contains(colorSchemeId),
    '未知 colorSchemeId: $colorSchemeId',
  );
  return switch (colorSchemeId) {
    'brand' || 'violet' => kBrandSeedColor,
    // 青瓷色 — teal 600
    'teal' => const Color(0xFF00897B),
    // 天青色 — cyan 600
    'cyan' => const Color(0xFF00ACC1),
    // 矢车菊色 — blue 600
    'blue' => const Color(0xFF1E88E5),
    // 靛蓝色
    'indigo' => const Color(0xFF3949AB),
    // 葡萄色 — deepPurple 600
    'deepPurple' => const Color(0xFF5E35B1),
    // 蔷薇色 — pink 600
    'pink' => const Color(0xFFD81B60),
    // 樱花色 — 略偏亮的粉红种子
    'sakura' => const Color(0xFFEC407A),
    // 琥珀色 — amber 600（避免 Colors.yellow 过亮导致 fidelity 发灰绿）
    'yellow' => const Color(0xFFFFB300),
    // 金盏花色 — orange 600
    'orange' => const Color(0xFFFB8C00),
    // 朱砂色 — deepOrange 700
    'deepOrange' => const Color(0xFFE64A19),
    // 苔绿色 — lightGreen 700
    'green' => const Color(0xFF689F38),
    _ => kBrandSeedColor,
  };
}
