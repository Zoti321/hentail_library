// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_radius_tokens.dart';

// **************************************************************************
// TailorAnnotationsGenerator
// **************************************************************************

mixin _$AppRadiusTokensTailorMixin on ThemeExtension<AppRadiusTokens> {
  double get xs;
  double get sm;
  double get md;
  double get lg;
  double get pill;

  @override
  AppRadiusTokens copyWith({
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? pill,
  }) {
    return AppRadiusTokens(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      pill: pill ?? this.pill,
    );
  }

  @override
  AppRadiusTokens lerp(
    covariant ThemeExtension<AppRadiusTokens>? other,
    double t,
  ) {
    if (other is! AppRadiusTokens) return this as AppRadiusTokens;
    return AppRadiusTokens(
      xs: t < 0.5 ? xs : other.xs,
      sm: t < 0.5 ? sm : other.sm,
      md: t < 0.5 ? md : other.md,
      lg: t < 0.5 ? lg : other.lg,
      pill: t < 0.5 ? pill : other.pill,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AppRadiusTokens &&
            const DeepCollectionEquality().equals(xs, other.xs) &&
            const DeepCollectionEquality().equals(sm, other.sm) &&
            const DeepCollectionEquality().equals(md, other.md) &&
            const DeepCollectionEquality().equals(lg, other.lg) &&
            const DeepCollectionEquality().equals(pill, other.pill));
  }

  @override
  int get hashCode {
    return Object.hash(
      runtimeType.hashCode,
      const DeepCollectionEquality().hash(xs),
      const DeepCollectionEquality().hash(sm),
      const DeepCollectionEquality().hash(md),
      const DeepCollectionEquality().hash(lg),
      const DeepCollectionEquality().hash(pill),
    );
  }
}
