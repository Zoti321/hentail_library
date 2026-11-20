import 'package:hentai_library/shared/application/navigation/app_routes.dart';
import 'package:test/test.dart';

void main() {
  group('AppRoutes builders', () {
    test('encodes ids in catalog detail paths', () {
      expect(AppRoutes.comic('a/b c'), '/comic/a%2Fb%20c');
      expect(AppRoutes.series('s 1'), '/series/s%201');
      expect(AppRoutes.library('lib-a'), '/libraries/lib-a');
      expect(AppRoutes.author(7), '/author/7');
      expect(
        AppRoutes.imageSetDetail('lib x', 'set/1'),
        '/libraries/lib%20x/image-sets/set%2F1',
      );
    });

    test('metadata tab keeps query', () {
      expect(AppRoutes.metadataTab('authors'), '/metadata?tab=authors');
    });

    test('reader location encodes query', () {
      expect(
        AppRoutes.readerLocation(<String, String>{'comic_id': 'c1'}),
        '/reader?comic_id=c1',
      );
    });
  });

  group('AppRoutes predicates', () {
    test('libraryIdFromPath rejects legacy all; keeps browse library id', () {
      expect(AppRoutes.libraryIdFromPath('/libraries/lib-a'), 'lib-a');
      expect(AppRoutes.libraryIdFromPath(AppRoutes.legacyAll), isNull);
      expect(
        AppRoutes.libraryIdFromPath(
          AppRoutes.imageSetDetail('a', 'set-1'),
        ),
        'a',
      );
      expect(AppRoutes.libraryIdFromPath('/home'), isNull);
    });

    test('legacy paths redirect home', () {
      for (final String path in <String>[
        AppRoutes.local,
        AppRoutes.libraries,
        AppRoutes.legacyAll,
      ]) {
        expect(AppRoutes.legacyRedirectPath(path), AppRoutes.home);
      }
      expect(AppRoutes.legacyRedirectPath('/libraries/lib-a'), isNull);
    });

    test('catalog detail and reader predicates', () {
      expect(AppRoutes.isCatalogDetailPath('/comic/c1'), isTrue);
      expect(AppRoutes.isCatalogDetailPath('/series/s1'), isTrue);
      expect(
        AppRoutes.isCatalogDetailPath(
          AppRoutes.imageSetDetail('lib-1', 'set-a'),
        ),
        isTrue,
      );
      expect(AppRoutes.isCatalogDetailPath('/home'), isFalse);
      expect(AppRoutes.isReaderPath('/reader'), isTrue);
      expect(AppRoutes.isReaderPath('/reader?comic_id=c1'), isTrue);
      expect(AppRoutes.isReaderPath('/readers'), isFalse);
      final String readerLocation = AppRoutes.imageSetReaderLocation(
        libraryId: 'lib-1',
        imageSetId: 'set-a',
        queryParameters: const <String, String>{'start_index': '0'},
      );
      expect(
        AppRoutes.isImageSetReaderPath(Uri.parse(readerLocation).path),
        isTrue,
      );
      expect(
        AppRoutes.isImageSetDetailPath(
          AppRoutes.imageSetDetail('lib-1', 'set-a'),
        ),
        isTrue,
      );
      expect(
        AppRoutes.isImageSetLibraryPath(AppRoutes.library('lib-1')),
        isFalse,
      );
    });
  });
}
