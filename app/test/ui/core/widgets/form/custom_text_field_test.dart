import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/core/widgets/form/custom_text_field.dart';

void main() {
  const Color surface = Color(0xFFFFFFFF);
  const Color focusedBorder = Color(0xFF005FB8);
  const Color idleBorder = Color(0xFFCCCCCC);

  test('focused decoration changes border color only, no glow shadow', () {
    final BoxDecoration decoration = customTextFieldDecoration(
      isFocused: true,
      surface: surface,
      focusedBorder: focusedBorder,
      idleBorder: idleBorder,
    );

    expect(decoration.color, surface);
    expect(decoration.border, isA<Border>());
    final Border border = decoration.border! as Border;
    expect(border.top.color, focusedBorder);
    expect(decoration.boxShadow, isNull);
  });

  test('idle decoration uses idle border and no shadow', () {
    final BoxDecoration decoration = customTextFieldDecoration(
      isFocused: false,
      surface: surface,
      focusedBorder: focusedBorder,
      idleBorder: idleBorder,
    );

    final Border border = decoration.border! as Border;
    expect(border.top.color, idleBorder);
    expect(decoration.boxShadow, isNull);
  });
}
