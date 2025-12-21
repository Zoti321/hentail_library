import 'package:flutter/material.dart';

ColorScheme appFluentLightScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF005fb8),
  onPrimary: Colors.white,
  secondary: Color(0xFF4CAF50),
  onSecondary: Colors.white,
  error: Color(0xFFB00020),
  onError: Colors.white,
  surface: Colors.white,
  onSurface: Color(0xFF111827),
  surfaceContainer: Color(0xFFF3F3F3), // 容器背景色
  outline: Color(0xFFE5E7EB),
  outlineVariant: Color(0xFFD1D5DB),
  surfaceContainerHighest: Color(0xFFF9FAFB),
  onSurfaceVariant: Color(0xFF6B7280),
  primaryContainer: Color(0xFFE5E7EB).withAlpha(30),
  onPrimaryContainer: Color(0xFF005FB8),
  secondaryContainer: Color(0xFFE5E7EB),
  onSecondaryContainer: Color(0xFF374151),
  tertiary: Color(0xFF6B7280),
  onTertiary: Colors.white,
  tertiaryContainer: Color(0xFFE5E7EB),
  onTertiaryContainer: Color(0xFF4B5563),
  inverseSurface: Color(0xFF2563EB),
  inversePrimary: Color(0xFFEF4444),
  surfaceTint: Color(0xFF1e1e1e),
  shadow: Colors.black.withAlpha(4),
);

ColorScheme appFluentDarkScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFF6EB3FF),
  onPrimary: Color(0xFF003258),
  secondary: Color(0xFF6FCF97),
  onSecondary: Color(0xFF00391C),
  error: Color(0xFFF44336),
  onError: Color(0xFF690005),
  surface: Color(0xFF1A1A1A),
  onSurface: Color(0xFFE5E5E5),
  surfaceContainer: Color(0xFF2D2D2D),
  outline: Color(0xFF404040),
  outlineVariant: Color(0xFF525252),
  surfaceContainerHighest: Color(0xFF363636),
  onSurfaceVariant: Color(0xFFB0B0B0),
  primaryContainer: Color(0xFF004578),
  onPrimaryContainer: Color(0xFFC8E4FF),
  secondaryContainer: Color(0xFF004D2A),
  onSecondaryContainer: Color(0xFF8FE8B0),
  tertiary: Color(0xFFB0B0B0),
  onTertiary: Color(0xFF2A2A2A),
  tertiaryContainer: Color(0xFF404040),
  onTertiaryContainer: Color(0xFFD0D0D0),
  inverseSurface: Color(0xFF6EB3FF),
  inversePrimary: Color(0xFF005fb8),
  surfaceTint: Color(0xFF1e1e1e),
  shadow: Colors.black.withAlpha(80),
);

ColorScheme appFluentColorScheme(Brightness brightness) =>
    brightness == Brightness.dark ? appFluentDarkScheme : appFluentLightScheme;

ColorScheme get appFluentColorSchemeLight => appFluentLightScheme;

// 扩展颜色方案，添加项目中使用的其他颜色（根据 brightness 返回对应色值）
extension AppColorSchemeExtension on ColorScheme {
  Color get hoverBackground =>
      brightness == Brightness.dark ? const Color(0xFF363636) : const Color(0xFFF9FAFB);

  Color get textPrimary =>
      brightness == Brightness.dark ? const Color(0xFFE5E5E5) : const Color(0xFF111827);
  Color get textSecondary =>
      brightness == Brightness.dark ? const Color(0xFFB0B0B0) : const Color(0xFF374151);
  Color get textTertiary =>
      brightness == Brightness.dark ? const Color(0xFF909090) : const Color(0xFF6B7280);
  Color get textPlaceholder =>
      brightness == Brightness.dark ? const Color(0xFF707070) : const Color(0xFF9CA3AF);
  Color get textDisabled =>
      brightness == Brightness.dark ? const Color(0xFF525252) : const Color(0xFFD1D5DB);

  Color get primaryHover =>
      brightness == Brightness.dark ? const Color(0xFF8FC4FF) : const Color(0xFF004585);
  Color get buttonPressed =>
      brightness == Brightness.dark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(10);
  Color get buttonRipple =>
      brightness == Brightness.dark ? Colors.white.withAlpha(5) : Colors.black.withAlpha(5);

  Color get cardHover => brightness == Brightness.dark
      ? const Color(0xFF2D2D2D).withAlpha(245)
      : Colors.white.withAlpha(245);
  Color get cardShadow =>
      brightness == Brightness.dark ? Colors.black.withAlpha(60) : Colors.black.withAlpha(4);

  Color get iconDefault =>
      brightness == Brightness.dark ? const Color(0xFFB0B0B0) : const Color(0xFF6B7280);
  Color get iconSecondary =>
      brightness == Brightness.dark ? const Color(0xFF909090) : const Color(0xFF9CA3AF);
  Color get iconActive =>
      brightness == Brightness.dark ? const Color(0xFF6EB3FF) : const Color(0xFF005FB8);

  Color get borderSubtle =>
      brightness == Brightness.dark ? const Color(0xFF404040) : const Color(0xFFE5E7EB);
  Color get borderMedium =>
      brightness == Brightness.dark ? const Color(0xFF525252) : const Color(0xFFD1D5DB);
  Color get borderStrong =>
      brightness == Brightness.dark ? const Color(0xFF707070) : const Color(0xFF9CA3AF);

  Color get success => const Color(0xFF4CAF50);
  Color get warning => const Color(0xFFEF4444);
  Color get info => const Color(0xFF2563EB);

  Color get inputBorder =>
      brightness == Brightness.dark ? const Color(0xFF404040) : const Color(0xFFE5E7EB);
  Color get inputBorderActive =>
      brightness == Brightness.dark ? const Color(0xFF6EB3FF) : const Color(0xFF005FB8);
  Color get inputBackground =>
      brightness == Brightness.dark ? const Color(0xFF2D2D2D) : Colors.white;
  Color get inputBackgroundDisabled =>
      brightness == Brightness.dark ? const Color(0xFF252525) : const Color(0xFFF3F4F6);
}

extension WinTheme on ColorScheme {
  Color get winBackground =>
      brightness == Brightness.dark ? const Color(0xFF1A1A1A) : const Color(0xFFEAEAEA);
  Color get winForeground =>
      brightness == Brightness.dark ? const Color(0xFFE5E5E5) : const Color(0xFF1A1A1A);
  Color get winBorder =>
      brightness == Brightness.dark ? const Color(0xFF404040) : const Color(0xFFCCCCCC);
  Color get winShadow =>
      brightness == Brightness.dark ? const Color(0xFF303030) : const Color(0xFFAAAAAA);
  Color get winSurface => brightness == Brightness.dark
      ? const Color.fromRGBO(45, 45, 47, 1)
      : const Color.fromRGBO(230, 230, 232, 1);
  Color get sidebarBackground =>
      brightness == Brightness.dark ? const Color(0xFF202020) : const Color(0xFFF5F5F5);
}

extension ReaderPageTheme on ColorScheme {
  // 1. 全局背景
  Color get readerBackground => const Color(0xFF09090B);

  // 2. 悬浮控件 Floating UI
  Color get floatingUiBackground => const Color(0x99000000); // rgba(0,0,0,0.6)
  Color get floatingUiBorder =>
      const Color(0x1AFFFFFF); // rgba(255,255,255,0.1)
  Color get floatingUiDivider =>
      const Color(0x1AFFFFFF); // rgba(255,255,255,0.1)

  // 3. 文字与图标
  Color get readerTextIconPrimary =>
      const Color(0xE6FFFFFF); // rgba(255,255,255,0.9)
  Color get readerTextSecondary =>
      const Color(0x99FFFFFF); // rgba(255,255,255,0.6)
  Color get readerTextMuted => const Color(0x80FFFFFF); // rgba(255,255,255,0.5)
  Color get readerTextOnWhite => const Color(0xFF000000); // #000000

  // 4. 交互元素
  Color get activeButtonBg => const Color(0xFFFFFFFF); // #ffffff
  Color get hoverBg => const Color(0x1AFFFFFF); // rgba(255,255,255,0.1)
  Color get secondaryContainerBg => const Color(0x66000000); // rgba(0,0,0,0.4)

  // 5. 进度条 Slider
  Color get sliderActive => const Color(0xCCFFFFFF); // rgba(255,255,255,0.8)
  Color get sliderInactive => const Color(0x33FFFFFF); // rgba(255,255,255,0.2)

  // 6. 条漫模式特定
  Color get chapterEndDivider => const Color(0xFF27272A); // #27272a
  Color get chapterEndHintText => const Color(0xFF71717A); // #71717a
}
