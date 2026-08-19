import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/core/interaction/reader_input.dart';
import 'package:hentai_library/ui/features/reader/module/controller/reader_controller.dart';

void main() {
  group('resolveReaderTapZone', () {
    test('maps left and right thirds', () {
      expect(
        resolveReaderTapZone(globalX: 100, width: 1000),
        ReaderTapZone.left,
      );
      expect(
        resolveReaderTapZone(globalX: 500, width: 1000),
        ReaderTapZone.center,
      );
      expect(
        resolveReaderTapZone(globalX: 800, width: 1000),
        ReaderTapZone.right,
      );
    });
  });

  group('readerKeyboardCommandFor', () {
    test('arrows and space turn pages', () {
      expect(
        readerKeyboardCommandFor(
          LogicalKeyboardKey.arrowLeft,
          showControls: false,
        ),
        ReaderKeyboardCommand.prevPage,
      );
      expect(
        readerKeyboardCommandFor(
          LogicalKeyboardKey.arrowRight,
          showControls: false,
        ),
        ReaderKeyboardCommand.nextPage,
      );
      expect(
        readerKeyboardCommandFor(LogicalKeyboardKey.space, showControls: false),
        ReaderKeyboardCommand.nextPage,
      );
    });

    test('escape hides controls when they are visible', () {
      expect(
        readerKeyboardCommandFor(LogicalKeyboardKey.escape, showControls: true),
        ReaderKeyboardCommand.hideControls,
      );
    });

    test('escape exits when controls are hidden', () {
      expect(
        readerKeyboardCommandFor(
          LogicalKeyboardKey.escape,
          showControls: false,
        ),
        ReaderKeyboardCommand.exit,
      );
    });
  });
}
