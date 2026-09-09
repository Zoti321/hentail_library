import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/ports/clipboard_image_port.dart';
import 'package:hentai_library/domain/ports/comic_page_source_port.dart';
import 'package:hentai_library/domain/reading/page_image_copy.dart';

class _FakeComicPageSourcePort implements ComicPageSourcePort {
  _FakeComicPageSourcePort({this.pageBytes, this.error});

  final Uint8List? pageBytes;
  final Object? error;
  final List<int> requestedPageIndexes = <int>[];

  @override
  Future<Uint8List?> loadPageBytes({
    required Comic comic,
    required int pageIndex,
  }) async {
    requestedPageIndexes.add(pageIndex);
    if (error != null) {
      throw error!;
    }
    return pageBytes;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeClipboardImagePort implements ClipboardImagePort {
  _FakeClipboardImagePort({this.error});

  final Object? error;
  final List<Uint8List> writes = <Uint8List>[];

  @override
  Future<void> writePng(Uint8List pngBytes) async {
    if (error != null) {
      throw error!;
    }
    writes.add(pngBytes);
  }
}

Comic _comic() {
  final DateTime now = DateTime.utc(2026, 1, 1);
  return Comic(
    comicId: 'c1',
    path: '/tmp/comic',
    resourceType: ResourceType.zip,
    resourceSize: 1024,
    createdAt: now,
    lastUpdatedAt: now,
    title: 'Test',
    pageCount: 5,
  );
}

Uint8List _sourceBytes() => Uint8List.fromList(<int>[1, 2, 3, 4]);

Uint8List _encodedPng() => Uint8List.fromList(<int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0xAA,
]);

PageImageCopy _subject({
  required _FakeComicPageSourcePort pageSource,
  required _FakeClipboardImagePort clipboard,
  PageImagePngEncoder? encodePng,
}) {
  return PageImageCopy(
    pageSource: pageSource,
    clipboardImage: clipboard,
    encodePng: encodePng,
  );
}

void main() {
  group('PageImageCopy', () {
    test('loads requested page bytes, encodes PNG, writes clipboard', () async {
      final _FakeComicPageSourcePort pageSource = _FakeComicPageSourcePort(
        pageBytes: _sourceBytes(),
      );
      final _FakeClipboardImagePort clipboard = _FakeClipboardImagePort();
      final List<Uint8List> encodedInputs = <Uint8List>[];
      final PageImageCopy subject = _subject(
        pageSource: pageSource,
        clipboard: clipboard,
        encodePng: (Uint8List bytes) async {
          encodedInputs.add(bytes);
          return _encodedPng();
        },
      );

      await subject.execute(comic: _comic(), archivePageIndex: 4);

      expect(pageSource.requestedPageIndexes, <int>[4]);
      expect(encodedInputs, <Uint8List>[_sourceBytes()]);
      expect(clipboard.writes, <Uint8List>[_encodedPng()]);
    });

    test(
      'throws load failure and does not write clipboard when page load fails',
      () async {
        final _FakeComicPageSourcePort pageSource = _FakeComicPageSourcePort(
          error: StateError('io failed'),
        );
        final _FakeClipboardImagePort clipboard = _FakeClipboardImagePort();
        final PageImageCopy subject = _subject(
          pageSource: pageSource,
          clipboard: clipboard,
          encodePng: (_) async => _encodedPng(),
        );

        await expectLater(
          () => subject.execute(comic: _comic(), archivePageIndex: 1),
          throwsA(
            isA<PageImageCopyException>().having(
              (PageImageCopyException e) => e.message,
              'message',
              '加载页图失败（第 2 页）',
            ),
          ),
        );
        expect(clipboard.writes, isEmpty);
      },
    );

    test(
      'throws load failure and does not write clipboard when page bytes missing',
      () async {
        final _FakeComicPageSourcePort pageSource = _FakeComicPageSourcePort(
          pageBytes: null,
        );
        final _FakeClipboardImagePort clipboard = _FakeClipboardImagePort();
        final PageImageCopy subject = _subject(
          pageSource: pageSource,
          clipboard: clipboard,
          encodePng: (_) async => _encodedPng(),
        );

        await expectLater(
          () => subject.execute(comic: _comic(), archivePageIndex: 0),
          throwsA(isA<PageImageCopyException>()),
        );
        expect(clipboard.writes, isEmpty);
      },
    );

    test(
      'throws encode failure and does not write clipboard when encode fails',
      () async {
        final _FakeComicPageSourcePort pageSource = _FakeComicPageSourcePort(
          pageBytes: _sourceBytes(),
        );
        final _FakeClipboardImagePort clipboard = _FakeClipboardImagePort();
        final PageImageCopy subject = _subject(
          pageSource: pageSource,
          clipboard: clipboard,
          encodePng: (_) async => throw StateError('bad image'),
        );

        await expectLater(
          () => subject.execute(comic: _comic(), archivePageIndex: 0),
          throwsA(
            isA<PageImageCopyException>().having(
              (PageImageCopyException e) => e.message,
              'message',
              '转换页图失败（第 1 页）',
            ),
          ),
        );
        expect(clipboard.writes, isEmpty);
      },
    );

    test('throws clipboard failure after PNG encode', () async {
      final _FakeComicPageSourcePort pageSource = _FakeComicPageSourcePort(
        pageBytes: _sourceBytes(),
      );
      final _FakeClipboardImagePort clipboard = _FakeClipboardImagePort(
        error: StateError('clipboard unavailable'),
      );
      final PageImageCopy subject = _subject(
        pageSource: pageSource,
        clipboard: clipboard,
        encodePng: (_) async => _encodedPng(),
      );

      await expectLater(
        () => subject.execute(comic: _comic(), archivePageIndex: 2),
        throwsA(
          isA<PageImageCopyException>().having(
            (PageImageCopyException e) => e.message,
            'message',
            '写入剪贴板失败（第 3 页）',
          ),
        ),
      );
      expect(clipboard.writes, isEmpty);
    });
  });
}
