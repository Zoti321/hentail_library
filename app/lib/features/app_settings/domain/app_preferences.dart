import 'package:freezed_annotation/freezed_annotation.dart';

/// 应用外观：浅色 / 深色 / 跟随系统。
@JsonEnum(alwaysCreate: true)
enum AppThemePreference {
  @JsonValue('system')
  system,
  @JsonValue('light')
  light,
  @JsonValue('dark')
  dark,
}

/// 固定配色方案 id（非 Material Dynamic Color 运行时）；与 [AppThemePreference] 正交。
///
/// Seed 色映射见 `shared/ui/theme` 的 colorSchemeSeedForId；`brand` 为产品默认
///（定稿紫罗兰 / 与 `violet` 同 seed）。展示名用植物 / 矿物色名（如青瓷色）。
@JsonEnum(alwaysCreate: true)
enum AppColorSchemePreference {
  @JsonValue('brand')
  brand,
  @JsonValue('teal')
  teal,
  @JsonValue('cyan')
  cyan,
  @JsonValue('blue')
  blue,
  @JsonValue('indigo')
  indigo,
  @JsonValue('deepPurple')
  deepPurple,
  @JsonValue('violet')
  violet,
  @JsonValue('pink')
  pink,
  @JsonValue('sakura')
  sakura,
  @JsonValue('yellow')
  yellow,
  @JsonValue('orange')
  orange,
  @JsonValue('deepOrange')
  deepOrange,
  @JsonValue('green')
  green,
}

/// 应用语言：中文 / English / 跟随系统。
@JsonEnum(alwaysCreate: true)
enum AppLocalePreference {
  @JsonValue('system')
  system,
  @JsonValue('zh_CN')
  zhCn,
  @JsonValue('en')
  en,
}

/// UI 字体族：MI_Sans_Regular / Noto Sans（SC/JP 仅作 i18n fallback，不进设置项）。
@JsonEnum(alwaysCreate: true)
enum AppFontPreference {
  @JsonValue('miSans')
  miSans,
  @JsonValue('notoSans')
  notoSans,
}
