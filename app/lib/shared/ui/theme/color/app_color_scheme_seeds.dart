import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/theme/app_m3e_theme.dart';

/// 已知固定配色 id（与 `AppColorSchemePreference` JSON 值对齐）。
const Set<String> kKnownColorSchemeIds = <String>{
  'brand',
  'teal',
  'blue',
  'indigo',
  'violet',
  'pink',
  'yellow',
  'orange',
  'deepOrange',
};

/// Seed for [buildAppTheme] / [buildAppM3eThemeData] 的 `colorSchemeId`。
///
/// 色值参考 Kazumi `colorThemeTypes`；`brand` 定稿为紫罗兰
///（[kBrandSeedColor]），与偏好 id `violet` 同色、id 仍正交。
Color colorSchemeSeedForId(String colorSchemeId) {
  assert(
    kKnownColorSchemeIds.contains(colorSchemeId),
    '未知 colorSchemeId: $colorSchemeId',
  );
  return switch (colorSchemeId) {
    'brand' || 'violet' => kBrandSeedColor,
    'teal' => Colors.teal,
    'blue' => Colors.blue,
    'indigo' => Colors.indigo,
    'pink' => Colors.pink,
    'yellow' => Colors.yellow,
    'orange' => Colors.orange,
    'deepOrange' => Colors.deepOrange,
    _ => kBrandSeedColor,
  };
}
