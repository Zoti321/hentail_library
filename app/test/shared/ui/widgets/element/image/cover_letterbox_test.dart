import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/ui/widgets/element/image/cover_letterbox.dart';

void main() {
  const double boxAspect = 2 / 3;

  group('coverFitForAspects', () {
    test('equal aspects use cover', () {
      expect(
        coverFitForAspects(imageAspect: boxAspect, boxAspect: boxAspect),
        BoxFit.cover,
      );
    });

    test('within 8% tolerance uses cover', () {
      // Stay clearly inside the band to avoid float edge cases at exactly 8%.
      expect(
        coverFitForAspects(
          imageAspect: boxAspect * 1.07,
          boxAspect: boxAspect,
        ),
        BoxFit.cover,
      );
      expect(
        coverFitForAspects(
          imageAspect: boxAspect * 0.93,
          boxAspect: boxAspect,
        ),
        BoxFit.cover,
      );
    });

    test('beyond tolerance uses contain', () {
      expect(
        coverFitForAspects(
          imageAspect: boxAspect * 1.09,
          boxAspect: boxAspect,
        ),
        BoxFit.contain,
      );
      expect(
        coverFitForAspects(imageAspect: 1.0, boxAspect: boxAspect),
        BoxFit.contain,
      );
      expect(
        coverFitForAspects(imageAspect: 0.5, boxAspect: boxAspect),
        BoxFit.contain,
      );
    });

    test('invalid aspects use contain', () {
      expect(
        coverFitForAspects(imageAspect: 0, boxAspect: boxAspect),
        BoxFit.contain,
      );
      expect(
        coverFitForAspects(imageAspect: boxAspect, boxAspect: 0),
        BoxFit.contain,
      );
      expect(
        coverFitForAspects(imageAspect: -1, boxAspect: boxAspect),
        BoxFit.contain,
      );
    });
  });

  testWidgets('coverLetterboxColor tracks ColorScheme.surfaceContainerHighest', (
    WidgetTester tester,
  ) async {
    late Color resolved;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          ),
        ),
        home: Builder(
          builder: (BuildContext context) {
            resolved = coverLetterboxColor(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final ColorScheme scheme = Theme.of(
      tester.element(find.byType(SizedBox)),
    ).colorScheme;
    expect(resolved, scheme.surfaceContainerHighest);
  });
}
