// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_spacing_tokens.dart';

// **************************************************************************
// TailorAnnotationsGenerator
// **************************************************************************

mixin _$AppSpacingTokensTailorMixin on ThemeExtension<AppSpacingTokens> {
  double get xs;
  double get sm;
  double get md;
  double get lg;
  double get xl;

  @override
  AppSpacingTokens copyWith({
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
  }) {
    return AppSpacingTokens(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
    );
  }

  @override
  AppSpacingTokens lerp(
    covariant ThemeExtension<AppSpacingTokens>? other,
    double t,
  ) {
    if (other is! AppSpacingTokens) return this as AppSpacingTokens;
    return AppSpacingTokens(
      xs: t < 0.5 ? xs : other.xs,
      sm: t < 0.5 ? sm : other.sm,
      md: t < 0.5 ? md : other.md,
      lg: t < 0.5 ? lg : other.lg,
      xl: t < 0.5 ? xl : other.xl,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AppSpacingTokens &&
            const DeepCollectionEquality().equals(xs, other.xs) &&
            const DeepCollectionEquality().equals(sm, other.sm) &&
            const DeepCollectionEquality().equals(md, other.md) &&
            const DeepCollectionEquality().equals(lg, other.lg) &&
            const DeepCollectionEquality().equals(xl, other.xl));
  }

  @override
  int get hashCode {
    return Object.hash(
      runtimeType.hashCode,
      const DeepCollectionEquality().hash(xs),
      const DeepCollectionEquality().hash(sm),
      const DeepCollectionEquality().hash(md),
      const DeepCollectionEquality().hash(lg),
      const DeepCollectionEquality().hash(xl),
    );
  }
}
