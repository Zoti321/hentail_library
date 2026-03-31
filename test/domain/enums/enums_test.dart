import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/util/enums.dart';

void main() {
  group('ScannedItemType', () {
    test('has expected values', () {
      expect(ScannedItemType.values, contains(ScannedItemType.dir));
      expect(ScannedItemType.values, contains(ScannedItemType.zip));
      expect(ScannedItemType.values, contains(ScannedItemType.epub));
      expect(ScannedItemType.values, contains(ScannedItemType.cbz));
      expect(ScannedItemType.values.length, 4);
    });
  });
}
