// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_shadow_tokens.dart';

// **************************************************************************
// TailorAnnotationsGenerator
// **************************************************************************

mixin _$AppShadowTokensTailorMixin on ThemeExtension<AppShadowTokens> {
  Color get catalogCardRest;
  Color get catalogCardHover;
  Color get dialogPrimary;
  Color get dialogSecondary;
  Color get toastPrimary;
  Color get toastSecondary;
  Color get contextMenu;

  @override
  AppShadowTokens copyWith({
    Color? catalogCardRest,
    Color? catalogCardHover,
    Color? dialogPrimary,
    Color? dialogSecondary,
    Color? toastPrimary,
    Color? toastSecondary,
    Color? contextMenu,
  }) {
    return AppShadowTokens(
      catalogCardRest: catalogCardRest ?? this.catalogCardRest,
      catalogCardHover: catalogCardHover ?? this.catalogCardHover,
      dialogPrimary: dialogPrimary ?? this.dialogPrimary,
      dialogSecondary: dialogSecondary ?? this.dialogSecondary,
      toastPrimary: toastPrimary ?? this.toastPrimary,
      toastSecondary: toastSecondary ?? this.toastSecondary,
      contextMenu: contextMenu ?? this.contextMenu,
    );
  }

  @override
  AppShadowTokens lerp(
    covariant ThemeExtension<AppShadowTokens>? other,
    double t,
  ) {
    if (other is! AppShadowTokens) return this as AppShadowTokens;
    return AppShadowTokens(
      catalogCardRest: Color.lerp(catalogCardRest, other.catalogCardRest, t)!,
      catalogCardHover: Color.lerp(
        catalogCardHover,
        other.catalogCardHover,
        t,
      )!,
      dialogPrimary: Color.lerp(dialogPrimary, other.dialogPrimary, t)!,
      dialogSecondary: Color.lerp(dialogSecondary, other.dialogSecondary, t)!,
      toastPrimary: Color.lerp(toastPrimary, other.toastPrimary, t)!,
      toastSecondary: Color.lerp(toastSecondary, other.toastSecondary, t)!,
      contextMenu: Color.lerp(contextMenu, other.contextMenu, t)!,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AppShadowTokens &&
            const DeepCollectionEquality().equals(
              catalogCardRest,
              other.catalogCardRest,
            ) &&
            const DeepCollectionEquality().equals(
              catalogCardHover,
              other.catalogCardHover,
            ) &&
            const DeepCollectionEquality().equals(
              dialogPrimary,
              other.dialogPrimary,
            ) &&
            const DeepCollectionEquality().equals(
              dialogSecondary,
              other.dialogSecondary,
            ) &&
            const DeepCollectionEquality().equals(
              toastPrimary,
              other.toastPrimary,
            ) &&
            const DeepCollectionEquality().equals(
              toastSecondary,
              other.toastSecondary,
            ) &&
            const DeepCollectionEquality().equals(
              contextMenu,
              other.contextMenu,
            ));
  }

  @override
  int get hashCode {
    return Object.hash(
      runtimeType.hashCode,
      const DeepCollectionEquality().hash(catalogCardRest),
      const DeepCollectionEquality().hash(catalogCardHover),
      const DeepCollectionEquality().hash(dialogPrimary),
      const DeepCollectionEquality().hash(dialogSecondary),
      const DeepCollectionEquality().hash(toastPrimary),
      const DeepCollectionEquality().hash(toastSecondary),
      const DeepCollectionEquality().hash(contextMenu),
    );
  }
}
