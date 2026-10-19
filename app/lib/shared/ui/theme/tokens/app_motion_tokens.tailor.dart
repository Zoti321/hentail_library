// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_motion_tokens.dart';

// **************************************************************************
// TailorAnnotationsGenerator
// **************************************************************************

mixin _$AppMotionTokensTailorMixin on ThemeExtension<AppMotionTokens> {
  Duration get durationFast;
  Duration get durationMedium;

  @override
  AppMotionTokens copyWith({Duration? durationFast, Duration? durationMedium}) {
    return AppMotionTokens(
      durationFast: durationFast ?? this.durationFast,
      durationMedium: durationMedium ?? this.durationMedium,
    );
  }

  @override
  AppMotionTokens lerp(
    covariant ThemeExtension<AppMotionTokens>? other,
    double t,
  ) {
    if (other is! AppMotionTokens) return this as AppMotionTokens;
    return AppMotionTokens(
      durationFast: t < 0.5 ? durationFast : other.durationFast,
      durationMedium: t < 0.5 ? durationMedium : other.durationMedium,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AppMotionTokens &&
            const DeepCollectionEquality().equals(
              durationFast,
              other.durationFast,
            ) &&
            const DeepCollectionEquality().equals(
              durationMedium,
              other.durationMedium,
            ));
  }

  @override
  int get hashCode {
    return Object.hash(
      runtimeType.hashCode,
      const DeepCollectionEquality().hash(durationFast),
      const DeepCollectionEquality().hash(durationMedium),
    );
  }
}
