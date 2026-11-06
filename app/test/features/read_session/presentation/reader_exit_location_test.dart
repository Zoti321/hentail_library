import 'package:test/test.dart';
import 'package:hentai_library/features/read_session/presentation/reader_exit_location.dart';

void main() {
  group('resolveReaderExitNavigation', () {
    test('pops when the stack can pop (keeps library browse under detail)', () {
      expect(
        resolveReaderExitNavigation(canPop: true, comicId: 'comic-a'),
        isNull,
      );
    });

    test('goes to comic detail when stack cannot pop', () {
      expect(
        resolveReaderExitNavigation(canPop: false, comicId: 'comic-a'),
        '/comic/comic-a',
      );
    });

    test('goes to all libraries when cannot pop and comic id blank', () {
      expect(
        resolveReaderExitNavigation(canPop: false, comicId: ' '),
        '/libraries/all',
      );
    });
  });

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
