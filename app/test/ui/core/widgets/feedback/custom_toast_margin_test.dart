import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/core/widgets/feedback/custom_toast.dart';

void main() {
  group('toastOuterMargin', () {
    test('pins compact toasts to the bottom with equal side inset', () {
      expect(
        toastOuterMargin(const Size(360, 800)),
        const EdgeInsets.fromLTRB(24, 0, 24, 24),
      );
    });

    test('keeps expanded toasts at the bottom-right', () {
      expect(
        toastOuterMargin(const Size(1400, 900)),
        const EdgeInsets.only(left: 996, bottom: 24, right: 24),
      );
    });

    test('adds bottom-bar inset so compact toasts sit above chrome', () {
      expect(
        toastOuterMargin(const Size(360, 800), bottomInset: 56),
        const EdgeInsets.fromLTRB(24, 0, 24, 80),
      );
    });
  });
}
