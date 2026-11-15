import 'package:hentai_library/features/reader/presentation/patterns/reader/reader_tap_zone.dart';
import 'package:test/test.dart';

void main() {
  test('edge fifths flip pages, center toggles chrome', () {
    expect(
      resolveReaderViewportTapZone(localX: 100, width: 1000),
      ReaderViewportTapZone.left,
    );
    expect(
      resolveReaderViewportTapZone(localX: 500, width: 1000),
      ReaderViewportTapZone.center,
    );
    expect(
      resolveReaderViewportTapZone(localX: 850, width: 1000),
      ReaderViewportTapZone.right,
    );
  });
}
