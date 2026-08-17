import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/features/reader/reader_exit_location.dart';

void main() {
  group('resolveReaderExitLocation', () {
    test('always returns comic detail when comicId is present', () {
      expect(
        resolveReaderExitLocation(comicId: 'comic-a'),
        '/comic/${Uri.encodeComponent('comic-a')}',
      );
    });

    test('encodes comicId in path', () {
      expect(
        resolveReaderExitLocation(comicId: 'comic/with space'),
        '/comic/${Uri.encodeComponent('comic/with space')}',
      );
    });

    test('falls back to library when comicId is blank', () {
      expect(resolveReaderExitLocation(comicId: ' '), '/libraries/all');
    });
  });
}
