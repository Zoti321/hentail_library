import 'package:hentai_library/features/reader/presentation/widgets/viewport/reader_page_crossfade_policy.dart';
import 'package:test/test.dart';

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
