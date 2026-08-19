import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/feedback/custom_toast.dart';

void main() {
  group('toastMaxWidth', () {
    test('caps compact toasts to the inset content width', () {
      expect(toastMaxWidth(360), 312);
      expect(toastMaxWidth(599), 380);
    });

    test('keeps medium toasts at the 380 desktop width', () {
      expect(toastMaxWidth(800), 380);
      expect(toastMaxWidth(1023), 380);
    });

    test('widens expanded toasts so the bar is not stub-short', () {
      expect(toastMaxWidth(1024), 480);
      expect(toastMaxWidth(1400), 480);
    });
  });

  group('toastContentPadding', () {
    test('uses denser padding below expanded', () {
      expect(
        toastContentPadding(800),
        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      );
    });

    test('uses taller padding on expanded viewports', () {
      expect(
        toastContentPadding(1400),
        const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      );
    });
  });

  group('toastOuterMargin', () {
    test('pins compact toasts to the bottom with equal side inset', () {
      expect(
        toastOuterMargin(const Size(360, 800)),
        const EdgeInsets.fromLTRB(24, 0, 24, 24),
      );
    });

    test(
      'keeps expanded toasts at the bottom-right with the expanded width',
      () {
        expect(
          toastOuterMargin(const Size(1400, 900)),
          const EdgeInsets.only(left: 896, bottom: 24, right: 24),
        );
      },
    );

    test('pins medium toasts at the bottom-right with the medium width', () {
      expect(
        toastOuterMargin(const Size(800, 900)),
        const EdgeInsets.only(left: 396, bottom: 24, right: 24),
      );
    });

    test('adds bottom-bar inset so compact toasts sit above chrome', () {
      expect(
        toastOuterMargin(const Size(360, 800), bottomInset: 56),
        const EdgeInsets.fromLTRB(24, 0, 24, 80),
      );
    });
  });

  testWidgets(
    'toast surface is an opaque fill lifted by shadows, without a border',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(Brightness.light),
          home: const Scaffold(
            body: SizedBox(
              width: 480,
              child: CustomToast(message: '已保存', type: AppToastType.success),
            ),
          ),
        ),
      );

      final DecoratedBox box = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(CustomToast),
          matching: find.byType(DecoratedBox),
        ),
      );
      final BoxDecoration decoration = box.decoration as BoxDecoration;
      expect(decoration.border, isNull);
      expect(decoration.color, isNotNull);
      expect(decoration.color!.a, 1.0);
      expect(decoration.boxShadow, isNotNull);
      expect(decoration.boxShadow, isNotEmpty);
    },
  );
}
