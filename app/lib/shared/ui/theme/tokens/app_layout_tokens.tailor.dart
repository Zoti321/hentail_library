// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_layout_tokens.dart';

// **************************************************************************
// TailorAnnotationsGenerator
// **************************************************************************

mixin _$AppLayoutTokensTailorMixin on ThemeExtension<AppLayoutTokens> {
  double get contentHorizontalPadding;
  double get contentVerticalPadding;
  EdgeInsets get contentAreaPadding;

  @override
  AppLayoutTokens copyWith({
    double? contentHorizontalPadding,
    double? contentVerticalPadding,
    EdgeInsets? contentAreaPadding,
  }) {
    return AppLayoutTokens(
      contentHorizontalPadding:
          contentHorizontalPadding ?? this.contentHorizontalPadding,
      contentVerticalPadding:
          contentVerticalPadding ?? this.contentVerticalPadding,
    );
  }

  @override
  AppLayoutTokens lerp(
    covariant ThemeExtension<AppLayoutTokens>? other,
    double t,
  ) {
    if (other is! AppLayoutTokens) return this as AppLayoutTokens;
    return AppLayoutTokens(
      contentHorizontalPadding: t < 0.5
          ? contentHorizontalPadding
          : other.contentHorizontalPadding,
      contentVerticalPadding: t < 0.5
          ? contentVerticalPadding
          : other.contentVerticalPadding,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AppLayoutTokens &&
            const DeepCollectionEquality().equals(
              contentHorizontalPadding,
              other.contentHorizontalPadding,
            ) &&
            const DeepCollectionEquality().equals(
              contentVerticalPadding,
              other.contentVerticalPadding,
            ) &&
            const DeepCollectionEquality().equals(
              contentAreaPadding,
              other.contentAreaPadding,
            ));
  }

  @override
  int get hashCode {
    return Object.hash(
      runtimeType.hashCode,
      const DeepCollectionEquality().hash(contentHorizontalPadding),
      const DeepCollectionEquality().hash(contentVerticalPadding),
      const DeepCollectionEquality().hash(contentAreaPadding),
    );
  }
}
