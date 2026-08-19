import 'package:flutter/services.dart';
import 'package:hentai_library/ui/features/reader/module/controller/reader_controller.dart';

/// Maps a horizontal tap to the classic reader thirds.
ReaderTapZone resolveReaderTapZone({
  required double globalX,
  required double width,
}) {
  if (width <= 0) {
    return ReaderTapZone.center;
  }
  if (globalX < width * 0.3) {
    return ReaderTapZone.left;
  }
  if (globalX > width * 0.7) {
    return ReaderTapZone.right;
  }
  return ReaderTapZone.center;
}

enum ReaderKeyboardCommand { prevPage, nextPage, hideControls, exit }

ReaderKeyboardCommand? readerKeyboardCommandFor(
  LogicalKeyboardKey key, {
  required bool showControls,
}) {
  if (key == LogicalKeyboardKey.arrowLeft) {
    return ReaderKeyboardCommand.prevPage;
  }
  if (key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.space) {
    return ReaderKeyboardCommand.nextPage;
  }
  if (key == LogicalKeyboardKey.escape) {
    return showControls
        ? ReaderKeyboardCommand.hideControls
        : ReaderKeyboardCommand.exit;
  }
  return null;
}
