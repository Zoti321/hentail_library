import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/ui/widgets/element/image/cover_letterbox.dart';

/// Minimal 1×1 JPEG (SOF0 width=1 height=1).
Uint8List _tinyJpeg({required int width, required int height}) {
  return Uint8List.fromList(<int>[
    0xFF, 0xD8, // SOI
    0xFF, 0xC0, // SOF0
    0x00, 0x0B, // length
    0x08, // precision
    (height >> 8) & 0xFF, height & 0xFF,
    (width >> 8) & 0xFF, width & 0xFF,
    0x01, // components
    0x01, 0x11, 0x00, // component
    0xFF, 0xD9, // EOI
  ]);
}

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
      expect(
        coverFitForAspects(imageAspect: boxAspect * 1.07, boxAspect: boxAspect),
        BoxFit.cover,
      );
      expect(
        coverFitForAspects(imageAspect: boxAspect * 0.93, boxAspect: boxAspect),
        BoxFit.cover,
      );
    });

    test('beyond tolerance uses contain', () {
      expect(
        coverFitForAspects(imageAspect: boxAspect * 1.09, boxAspect: boxAspect),
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

  group('peekCoverImageSize', () {
    test('reads JPEG SOF dimensions', () {
      final Size? size = peekCoverImageSize(_tinyJpeg(width: 200, height: 300));
      expect(size, const Size(200, 300));
    });

    test('null/short bytes return null', () {
      expect(peekCoverImageSize(null), isNull);
      expect(peekCoverImageSize(Uint8List(0)), isNull);
    });
  });

  test('coverFitForImageSize peeks soft-crop for near-2:3 JPEG', () {
    final Size? size = peekCoverImageSize(_tinyJpeg(width: 200, height: 300));
    expect(
      coverFitForImageSize(imageSize: size, boxAspect: boxAspect),
      BoxFit.cover,
    );
  });

  testWidgets(
    'coverLetterboxColor tracks ColorScheme.surfaceContainerHighest',
    (WidgetTester tester) async {
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

      final ColorScheme scheme = Theme.of(tester.element(find.byType(SizedBox)))
          .colorScheme;
      expect(resolved, scheme.surfaceContainerHighest);
    },
  );
}
