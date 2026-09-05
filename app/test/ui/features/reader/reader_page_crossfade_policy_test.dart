import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/features/reader/module/widgets/viewport/reader_page_crossfade_policy.dart';

void main() {
  group('readerPageCrossfadeEnabled', () {
    test('enabled when motion is not reduced', () {
      expect(readerPageCrossfadeEnabled(reduceMotion: false), isTrue);
    });

    test('disabled when reduce motion is on', () {
      expect(readerPageCrossfadeEnabled(reduceMotion: true), isFalse);
    });
  });
}
