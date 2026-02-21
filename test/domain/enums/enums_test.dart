import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/enums/enums.dart';

void main() {
  group('ScannedItemType', () {
    test('has expected values for sync report', () {
      expect(ScannedItemType.values, contains(ScannedItemType.folder));
      expect(ScannedItemType.values, contains(ScannedItemType.epub));
      expect(ScannedItemType.values, contains(ScannedItemType.archive));
      expect(ScannedItemType.values.length, 3);
    });
  });
}
