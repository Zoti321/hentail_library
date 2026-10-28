import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/patterns/reader/md3e_reader_tap_zone.dart';

void main() {
  test('thirds match production reader zones', () {
    expect(
      md3eResolveReaderTapZone(localX: 100, width: 1000),
      Md3eReaderTapZone.left,
    );
    expect(
      md3eResolveReaderTapZone(localX: 500, width: 1000),
      Md3eReaderTapZone.center,
    );
    expect(
      md3eResolveReaderTapZone(localX: 800, width: 1000),
      Md3eReaderTapZone.right,
    );
  });
}
