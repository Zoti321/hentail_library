// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_text_tokens.dart';

// **************************************************************************
// TailorAnnotationsGenerator
// **************************************************************************

mixin _$AppTextTokensTailorMixin on ThemeExtension<AppTextTokens> {
  double get labelXs;
  double get bodySm;
  double get bodyMd;
  double get bodyLg;
  double get titleSm;
  double get titleMd;
  double get titleLg;

  @override
  AppTextTokens copyWith({
    double? labelXs,
    double? bodySm,
    double? bodyMd,
    double? bodyLg,
    double? titleSm,
    double? titleMd,
    double? titleLg,
  }) {
    return AppTextTokens(
      labelXs: labelXs ?? this.labelXs,
      bodySm: bodySm ?? this.bodySm,
      bodyMd: bodyMd ?? this.bodyMd,
      bodyLg: bodyLg ?? this.bodyLg,
      titleSm: titleSm ?? this.titleSm,
      titleMd: titleMd ?? this.titleMd,
      titleLg: titleLg ?? this.titleLg,
    );
  }

  @override
  AppTextTokens lerp(covariant ThemeExtension<AppTextTokens>? other, double t) {
    if (other is! AppTextTokens) return this as AppTextTokens;
    return AppTextTokens(
      labelXs: t < 0.5 ? labelXs : other.labelXs,
      bodySm: t < 0.5 ? bodySm : other.bodySm,
      bodyMd: t < 0.5 ? bodyMd : other.bodyMd,
      bodyLg: t < 0.5 ? bodyLg : other.bodyLg,
      titleSm: t < 0.5 ? titleSm : other.titleSm,
      titleMd: t < 0.5 ? titleMd : other.titleMd,
      titleLg: t < 0.5 ? titleLg : other.titleLg,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AppTextTokens &&
            const DeepCollectionEquality().equals(labelXs, other.labelXs) &&
            const DeepCollectionEquality().equals(bodySm, other.bodySm) &&
            const DeepCollectionEquality().equals(bodyMd, other.bodyMd) &&
            const DeepCollectionEquality().equals(bodyLg, other.bodyLg) &&
            const DeepCollectionEquality().equals(titleSm, other.titleSm) &&
            const DeepCollectionEquality().equals(titleMd, other.titleMd) &&
            const DeepCollectionEquality().equals(titleLg, other.titleLg));
  }

  @override
  int get hashCode {
    return Object.hash(
      runtimeType.hashCode,
      const DeepCollectionEquality().hash(labelXs),
      const DeepCollectionEquality().hash(bodySm),
      const DeepCollectionEquality().hash(bodyMd),
      const DeepCollectionEquality().hash(bodyLg),
      const DeepCollectionEquality().hash(titleSm),
      const DeepCollectionEquality().hash(titleMd),
      const DeepCollectionEquality().hash(titleLg),
    );
  }
}
