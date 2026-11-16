// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_theme_tokens.dart';

// **************************************************************************
// TailorAnnotationsGenerator
// **************************************************************************

mixin _$AppThemeTokensTailorMixin on ThemeExtension<AppThemeTokens> {
  AppTextTokens get text;
  AppRadiusTokens get radius;
  AppSpacingTokens get spacing;
  AppLayoutTokens get layout;

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
  AppThemeTokens lerp(
    covariant ThemeExtension<AppThemeTokens>? other,
    double t,
  ) {
    if (other is! AppThemeTokens) return this as AppThemeTokens;
    return AppThemeTokens(
      text: text.lerp(other.text, t),
      radius: radius.lerp(other.radius, t),
      spacing: spacing.lerp(other.spacing, t),
      layout: layout.lerp(other.layout, t),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AppThemeTokens &&
            const DeepCollectionEquality().equals(text, other.text) &&
            const DeepCollectionEquality().equals(radius, other.radius) &&
            const DeepCollectionEquality().equals(spacing, other.spacing) &&
            const DeepCollectionEquality().equals(layout, other.layout));
  }

  @override
  int get hashCode {
    return Object.hash(
      runtimeType.hashCode,
      const DeepCollectionEquality().hash(text),
      const DeepCollectionEquality().hash(radius),
      const DeepCollectionEquality().hash(spacing),
      const DeepCollectionEquality().hash(layout),
    );
  }
}
