import 'package:flutter/material.dart';
import 'package:hentai_library/core/util/utils.dart';

@immutable
class AppThemeTokens extends ThemeExtension<AppThemeTokens> {
  final AppTextTokens text;
  final AppRadiusTokens radius;
  final AppSpacingTokens spacing;

  const AppThemeTokens({
    required this.text,
    required this.radius,
    required this.spacing,
  });

  factory AppThemeTokens.light() => const AppThemeTokens(
    text: AppTextTokens(
      labelXs: 12,
      bodySm: 13,
      bodyMd: 14,
      bodyLg: 16,
      titleSm: 16,
      titleMd: 18,
      titleLg: 22,
    ),
    radius: AppRadiusTokens(
      xs: 4,
      sm: 6,
      md: 8,
      lg: 12,
      pill: 999,
    ),
    spacing: AppSpacingTokens(
      xs: 4,
      sm: 8,
      md: 12,
      lg: 16,
      xl: 20,
    ),
  );

  factory AppThemeTokens.dark() => AppThemeTokens.light();

  @override
  AppThemeTokens copyWith({
    AppTextTokens? text,
    AppRadiusTokens? radius,
    AppSpacingTokens? spacing,
  }) {
    return AppThemeTokens(
      text: text ?? this.text,
      radius: radius ?? this.radius,
      spacing: spacing ?? this.spacing,
    );
  }

  @override
  ThemeExtension<AppThemeTokens> lerp(
    covariant ThemeExtension<AppThemeTokens>? other,
    double t,
  ) {
    if (other is! AppThemeTokens) return this;
    return AppThemeTokens(
      text: text.lerp(other.text, t),
      radius: radius.lerp(other.radius, t),
      spacing: spacing.lerp(other.spacing, t),
    );
  }
}

@immutable
class AppTextTokens {
  final double labelXs;
  final double bodySm;
  final double bodyMd;
  final double bodyLg;
  final double titleSm;
  final double titleMd;
  final double titleLg;

  const AppTextTokens({
    required this.labelXs,
    required this.bodySm,
    required this.bodyMd,
    required this.bodyLg,
    required this.titleSm,
    required this.titleMd,
    required this.titleLg,
  });

  AppTextTokens lerp(AppTextTokens other, double t) {
    return AppTextTokens(
      labelXs: _lerpDouble(labelXs, other.labelXs, t),
      bodySm: _lerpDouble(bodySm, other.bodySm, t),
      bodyMd: _lerpDouble(bodyMd, other.bodyMd, t),
      bodyLg: _lerpDouble(bodyLg, other.bodyLg, t),
      titleSm: _lerpDouble(titleSm, other.titleSm, t),
      titleMd: _lerpDouble(titleMd, other.titleMd, t),
      titleLg: _lerpDouble(titleLg, other.titleLg, t),
    );
  }
}

@immutable
class AppRadiusTokens {
  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double pill;

  const AppRadiusTokens({
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.pill,
  });

  AppRadiusTokens lerp(AppRadiusTokens other, double t) {
    return AppRadiusTokens(
      xs: _lerpDouble(xs, other.xs, t),
      sm: _lerpDouble(sm, other.sm, t),
      md: _lerpDouble(md, other.md, t),
      lg: _lerpDouble(lg, other.lg, t),
      pill: _lerpDouble(pill, other.pill, t),
    );
  }
}

@immutable
class AppSpacingTokens {
  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;

  const AppSpacingTokens({
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
  });

  AppSpacingTokens lerp(AppSpacingTokens other, double t) {
    return AppSpacingTokens(
      xs: _lerpDouble(xs, other.xs, t),
      sm: _lerpDouble(sm, other.sm, t),
      md: _lerpDouble(md, other.md, t),
      lg: _lerpDouble(lg, other.lg, t),
      xl: _lerpDouble(xl, other.xl, t),
    );
  }
}

double _lerpDouble(double a, double b, double t) => a + (b - a) * t;

extension ThemeTokensX on BuildContext {
  AppThemeTokens get tokens => Theme.of(this).extension<AppThemeTokens>()!;
}

ThemeData buildAppTheme(Brightness brightness) {
  final colorScheme = appFluentColorScheme(brightness);
  final tokens = brightness == Brightness.dark
      ? AppThemeTokens.dark()
      : AppThemeTokens.light();

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    fontFamily: 'MI_Sans_Regular',
    appBarTheme: _buildAppBarThemeData(colorScheme),
    navigationRailTheme: _buildNavRailThemeData(colorScheme),
    scrollbarTheme: ScrollbarThemeData(
      thumbVisibility: WidgetStateProperty.all(true),
      thickness: WidgetStateProperty.all(6),
      radius: const Radius.circular(999),
      thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
        final base = colorScheme.onSurfaceVariant;
        if (states.contains(WidgetState.dragged)) {
          return base.withOpacity(0.95);
        }
        if (states.contains(WidgetState.hovered)) {
          return base.withOpacity(0.85);
        }
        return base.withOpacity(0.65);
      }),
      trackColor: WidgetStateProperty.all(Colors.transparent),
      trackBorderColor: WidgetStateProperty.all(Colors.transparent),
    ),
    inputDecorationTheme: const InputDecorationTheme(hintMaxLines: 1),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
      },
    ),
    extensions: [tokens],
  );
}

AppBarTheme _buildAppBarThemeData(ColorScheme colorScheme) {
  return isDesktop
      ? AppBarTheme(
          surfaceTintColor: Colors.transparent,
          backgroundColor: colorScheme.surface,
          scrolledUnderElevation: 0.0,
        )
      : const AppBarTheme();
}

NavigationRailThemeData _buildNavRailThemeData(ColorScheme colorScheme) {
  return NavigationRailThemeData(
    labelType: NavigationRailLabelType.all,
    backgroundColor: colorScheme.surface,
    useIndicator: true,
  );
}

ColorScheme appFluentLightScheme = ColorScheme(
  brightness: Brightness.light,
  primary: const Color(0xFF005fb8),
  onPrimary: Colors.white,
  secondary: const Color(0xFF4CAF50),
  onSecondary: Colors.white,
  error: const Color(0xFFB00020),
  onError: Colors.white,
  surface: Colors.white,
  onSurface: const Color(0xFF111827),
  surfaceContainer: const Color(0xFFF3F3F3),
  outline: const Color(0xFFE5E7EB),
  outlineVariant: const Color(0xFFD1D5DB),
  surfaceContainerHighest: const Color(0xFFF9FAFB),
  onSurfaceVariant: const Color(0xFF6B7280),
  primaryContainer: const Color(0xFFE5E7EB).withAlpha(30),
  onPrimaryContainer: const Color(0xFF005FB8),
  secondaryContainer: const Color(0xFFE5E7EB),
  onSecondaryContainer: const Color(0xFF374151),
  tertiary: const Color(0xFF6B7280),
  onTertiary: Colors.white,
  tertiaryContainer: const Color(0xFFE5E7EB),
  onTertiaryContainer: const Color(0xFF4B5563),
  inverseSurface: const Color(0xFF2563EB),
  inversePrimary: const Color(0xFFEF4444),
  surfaceTint: const Color(0xFF1e1e1e),
  shadow: Colors.black.withAlpha(4),
);

ColorScheme appFluentDarkScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: const Color(0xFF6EB3FF),
  onPrimary: const Color(0xFF003258),
  secondary: const Color(0xFF6FCF97),
  onSecondary: const Color(0xFF00391C),
  error: const Color(0xFFF44336),
  onError: const Color(0xFF690005),
  surface: const Color(0xFF1A1A1A),
  onSurface: const Color(0xFFE5E5E5),
  surfaceContainer: const Color(0xFF2D2D2D),
  outline: const Color(0xFF404040),
  outlineVariant: const Color(0xFF525252),
  surfaceContainerHighest: const Color(0xFF363636),
  onSurfaceVariant: const Color(0xFFB0B0B0),
  primaryContainer: const Color(0xFF004578),
  onPrimaryContainer: const Color(0xFFC8E4FF),
  secondaryContainer: const Color(0xFF004D2A),
  onSecondaryContainer: const Color(0xFF8FE8B0),
  tertiary: const Color(0xFFB0B0B0),
  onTertiary: const Color(0xFF2A2A2A),
  tertiaryContainer: const Color(0xFF404040),
  onTertiaryContainer: const Color(0xFFD0D0D0),
  inverseSurface: const Color(0xFF6EB3FF),
  inversePrimary: const Color(0xFF005fb8),
  surfaceTint: const Color(0xFF1e1e1e),
  shadow: Colors.black.withAlpha(80),
);

ColorScheme appFluentColorScheme(Brightness brightness) =>
    brightness == Brightness.dark ? appFluentDarkScheme : appFluentLightScheme;

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
  Color get cardShadowHover =>
      brightness == Brightness.dark ? Colors.black.withAlpha(90) : Colors.black.withAlpha(26);
  Color get imagePlaceholder =>
      brightness == Brightness.dark ? const Color(0xFF3A3A3A) : const Color(0xFFE5E7EB);
  Color get imageFallback =>
      brightness == Brightness.dark ? const Color(0xFF4A4A4A) : const Color(0xFFD1D5DB);
  Color get overlayScrim =>
      brightness == Brightness.dark ? Colors.black.withAlpha(110) : Colors.black.withAlpha(50);

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
  Color get subtleTagBackground =>
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

  /// 侧栏导航项悬停：与 [sidebarBackground] 对比足够明显，避免沿用全局 [hoverBackground] 在浅色下几乎无差。
  Color get sidebarItemHoverBackground =>
      brightness == Brightness.dark
          ? const Color(0xFF343434)
          : const Color(0xFFE4E4E7);
}

extension ReaderPageTheme on ColorScheme {
  Color get readerBackground => const Color(0xFF09090B);
  Color get floatingUiBackground => const Color(0x99000000);
  Color get floatingUiBorder => const Color(0x1AFFFFFF);
  Color get floatingUiDivider => const Color(0x1AFFFFFF);
  Color get readerTextIconPrimary => const Color(0xE6FFFFFF);
  Color get readerTextSecondary => const Color(0x99FFFFFF);
  Color get readerTextMuted => const Color(0x80FFFFFF);
  Color get readerTextOnWhite => const Color(0xFF000000);
  Color get activeButtonBg => const Color(0xFFFFFFFF);
  Color get hoverBg => const Color(0x1AFFFFFF);
  Color get secondaryContainerBg => const Color(0x66000000);
  Color get sliderActive => const Color(0xCCFFFFFF);
  Color get sliderInactive => const Color(0x33FFFFFF);
  Color get chapterEndDivider => const Color(0xFF27272A);
  Color get chapterEndHintText => const Color(0xFF71717A);
  Color get readerPanelBackground => const Color(0x99000000);
  Color get readerPanelBorder => const Color(0xCCFFFFFF);
  Color get readerPanelSubtle => const Color(0x28000000);
  Color get readerPanelSubtleBorder => const Color(0x0DFFFFFF);
  Color get readerSliderOverlay => const Color(0x1AFFFFFF);
}
