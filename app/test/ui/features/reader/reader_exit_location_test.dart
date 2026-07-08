import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/features/reader/reader_exit_location.dart';

void main() {
  group('resolveReaderExitLocation', () {
    test('prefers series detail when seriesId is present', () {
      expect(
        resolveReaderExitLocation(
          comicId: 'comic-a',
          seriesId: 'series/1',
        ),
        '/series/${Uri.encodeComponent('series/1')}',
      );
    });

    test('falls back to comic detail when seriesId is absent', () {
      expect(
        resolveReaderExitLocation(comicId: 'comic-a'),
        '/comic/${Uri.encodeComponent('comic-a')}',
      );
    });

    test('treats blank seriesId as absent', () {
      expect(
        resolveReaderExitLocation(comicId: 'comic-a', seriesId: '  '),
        '/comic/${Uri.encodeComponent('comic-a')}',
      );
    });

    test('falls back to library when comicId is also blank', () {
      expect(resolveReaderExitLocation(comicId: ' '), '/local');
    });
  });
}
