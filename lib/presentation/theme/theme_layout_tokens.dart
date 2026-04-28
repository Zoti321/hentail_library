part of 'theme.dart';

@immutable
class AppThemeTokens extends ThemeExtension<AppThemeTokens> {
  final AppTextTokens text;
  final AppRadiusTokens radius;
  final AppSpacingTokens spacing;
  final AppLayoutTokens layout;

  const AppThemeTokens({
    required this.text,
    required this.radius,
    required this.spacing,
    required this.layout,
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
    radius: AppRadiusTokens(xs: 4, sm: 6, md: 8, lg: 12, pill: 999),
    spacing: AppSpacingTokens(xs: 4, sm: 8, md: 12, lg: 16, xl: 20),
    layout: AppLayoutTokens(
      contentHorizontalPadding: 48,
      contentVerticalPadding: 16,
    ),
  );

  factory AppThemeTokens.dark() => AppThemeTokens.light();

  @override
  AppThemeTokens copyWith({
    AppTextTokens? text,
    AppRadiusTokens? radius,
    AppSpacingTokens? spacing,
    AppLayoutTokens? layout,
  }) {
    return AppThemeTokens(
      text: text ?? this.text,
      radius: radius ?? this.radius,
      spacing: spacing ?? this.spacing,
      layout: layout ?? this.layout,
    );
  }

  @override
  ThemeExtension<AppThemeTokens> lerp(
    covariant ThemeExtension<AppThemeTokens>? other,
    double t,
  ) {
    if (other is! AppThemeTokens) {
      return this;
    }
    return AppThemeTokens(
      text: text.lerp(other.text, t),
      radius: radius.lerp(other.radius, t),
      spacing: spacing.lerp(other.spacing, t),
      layout: layout.lerp(other.layout, t),
    );
  }
}

@immutable
class AppLayoutTokens {
  final double contentHorizontalPadding;
  final double contentVerticalPadding;

  const AppLayoutTokens({
    required this.contentHorizontalPadding,
    required this.contentVerticalPadding,
  });

  EdgeInsets get contentAreaPadding => EdgeInsets.symmetric(
    horizontal: contentHorizontalPadding,
    vertical: contentVerticalPadding,
  );

  AppLayoutTokens lerp(AppLayoutTokens other, double t) {
    return AppLayoutTokens(
      contentHorizontalPadding: _lerpDouble(
        contentHorizontalPadding,
        other.contentHorizontalPadding,
        t,
      ),
      contentVerticalPadding: _lerpDouble(
        contentVerticalPadding,
        other.contentVerticalPadding,
        t,
      ),
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
