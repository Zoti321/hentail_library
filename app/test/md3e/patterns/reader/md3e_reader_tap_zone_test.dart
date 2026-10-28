import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/patterns/reader/md3e_reader_tap_zone.dart';

void main() {
  test('edge fifths flip pages, center toggles chrome', () {
    expect(
      md3eResolveReaderTapZone(localX: 100, width: 1000),
      Md3eReaderTapZone.left,
    );
    expect(
      md3eResolveReaderTapZone(localX: 500, width: 1000),
      Md3eReaderTapZone.center,
    );
    expect(
      md3eResolveReaderTapZone(localX: 850, width: 1000),
      Md3eReaderTapZone.right,
    );
  });
}
