import 'dart:typed_data';

import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/ports/comic_page_source_port.dart';
import 'package:hentai_library/domain/reading/read_session_exceptions.dart';
import 'package:hentai_library/domain/reading/read_session_loader.dart';
import 'package:hentai_library/domain/reading/read_session_page.dart';
import 'package:test/test.dart';

class _FakeComicPageSourcePort implements ComicPageSourcePort {
  _FakeComicPageSourcePort({required this.pages, this.error});

  final List<ReadSessionPage> pages;
  final Object? error;

  @override
  Future<List<ReadSessionPage>> loadPages(Comic comic) async {
    if (error != null) {
      throw error!;
    }
    return pages;
  }

  @override
  Future<Uint8List?> loadPageBytes({
    required Comic comic,
    required int pageIndex,
  }) async {
    return null;
  }
}

Comic _inputComic() {
  return Comic(
    comicId: 'c1',
    path: '/tmp/comic',
    resourceType: ResourceType.zip,
    title: 'Test',
  );
}

void main() {
  group('ReadSessionLoader', () {
    test('throws when page list is empty', () async {
      final ReadSessionLoader loader = ReadSessionLoader(
        pageSource: _FakeComicPageSourcePort(pages: <ReadSessionPage>[]),
      );
      expect(
        () => loader.loadPages(_inputComic()),
        throwsA(isA<ReadSessionPageLoadException>()),
      );
    });

    test('returns pages from port', () async {
      final ReadSessionLoader loader = ReadSessionLoader(
        pageSource: _FakeComicPageSourcePort(
          pages: <ReadSessionPage>[
            ReadSessionArchivePage(comicId: 'c1', pageIndex: 0),
          ],
        ),
      );
      final List<ReadSessionPage> actualPages = await loader.loadPages(
        _inputComic(),
      );
      expect(actualPages, hasLength(1));
    });

    test('wraps port failures as ReadSessionPageLoadException', () async {
      final ReadSessionLoader loader = ReadSessionLoader(
        pageSource: _FakeComicPageSourcePort(
          pages: <ReadSessionPage>[],
          error: StateError('io failed'),
        ),
      );
      expect(
        () => loader.loadPages(_inputComic()),
        throwsA(isA<ReadSessionPageLoadException>()),
      );
    });
  });
}
