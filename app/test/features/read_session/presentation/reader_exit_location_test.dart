import 'package:test/test.dart';
import 'package:hentai_library/features/read_session/presentation/reader_exit_location.dart';

void main() {
  group('resolveReaderExitLocation', () {
    test('returns comic detail when comic id is set', () {
      expect(resolveReaderExitLocation(comicId: 'comic-a'), '/comic/comic-a');
    });

    test('encodes comic id in path', () {
      expect(
        resolveReaderExitLocation(comicId: 'comic/with space'),
        '/comic/comic%2Fwith%20space',
      );
    });

    test('falls back to all libraries browse when comic id blank', () {
      expect(resolveReaderExitLocation(comicId: ' '), '/libraries/all');
    });
  });
}
