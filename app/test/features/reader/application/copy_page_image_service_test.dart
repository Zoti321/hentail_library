import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/reader/domain/reader_comic_ref.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/features/reader/domain/clipboard_image_port.dart';
import 'package:hentai_library/features/reader/application/copy_page_image_service.dart';

class _FakePageBytesLoader {
  _FakePageBytesLoader({this.pageBytes, this.error});

  final Uint8List? pageBytes;
  final Object? error;
  final List<({String comicId, int archivePageIndex})> requests =
      <({String comicId, int archivePageIndex})>[];

  Future<Uint8List?> call({
    required String comicId,
    required int archivePageIndex,
  }) async {
    requests.add((comicId: comicId, archivePageIndex: archivePageIndex));
    if (error != null) {
      throw error!;
    }
    return pageBytes;
  }
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

ReaderComicRef _comic({String comicId = 'c1'}) {
  return ReaderComicRef(
    comicId: comicId,
    path: '/tmp/comic',
    resourceType: ResourceType.zip,
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

CopyPageImageService _subject({
  required _FakePageBytesLoader loader,
  required _FakeClipboardImagePort clipboard,
  required PageImagePngEncoder encodePng,
}) {
  return CopyPageImageService(
    loadPageBytes: loader.call,
    clipboardImage: clipboard,
    encodePng: encodePng,
  );
}

void main() {
  group('CopyPageImageService', () {
    test('loads requested page bytes, encodes PNG, writes clipboard', () async {
      final _FakePageBytesLoader loader = _FakePageBytesLoader(
        pageBytes: _sourceBytes(),
      );
      final _FakeClipboardImagePort clipboard = _FakeClipboardImagePort();
      final List<Uint8List> encodedInputs = <Uint8List>[];
      final CopyPageImageService subject = _subject(
        loader: loader,
        clipboard: clipboard,
        encodePng: (Uint8List bytes) async {
          encodedInputs.add(bytes);
          return _encodedPng();
        },
      );

      await subject.execute(comic: _comic(), archivePageIndex: 4);

      expect(loader.requests.single.archivePageIndex, 4);
      expect(loader.requests.single.comicId, 'c1');
      expect(encodedInputs, <Uint8List>[_sourceBytes()]);
      expect(clipboard.writes, <Uint8List>[_encodedPng()]);
    });

    test('loads image-set session keys through the same loader seam', () async {
      const String sessionKey = 'image_set:lib-1:set-a';
      final _FakePageBytesLoader loader = _FakePageBytesLoader(
        pageBytes: _sourceBytes(),
      );
      final _FakeClipboardImagePort clipboard = _FakeClipboardImagePort();
      final CopyPageImageService subject = _subject(
        loader: loader,
        clipboard: clipboard,
        encodePng: (_) async => _encodedPng(),
      );

      await subject.execute(
        comic: _comic(comicId: sessionKey),
        archivePageIndex: 2,
      );

      expect(loader.requests.single.comicId, sessionKey);
      expect(loader.requests.single.archivePageIndex, 2);
      expect(clipboard.writes, <Uint8List>[_encodedPng()]);
    });

    test(
      'throws load failure and does not write clipboard when page load fails',
      () async {
        final _FakePageBytesLoader loader = _FakePageBytesLoader(
          error: StateError('io failed'),
        );
        final _FakeClipboardImagePort clipboard = _FakeClipboardImagePort();
        final CopyPageImageService subject = _subject(
          loader: loader,
          clipboard: clipboard,
          encodePng: (_) async => _encodedPng(),
        );

        await expectLater(
          () => subject.execute(comic: _comic(), archivePageIndex: 1),
          throwsA(
            isA<CopyPageImageException>().having(
              (CopyPageImageException e) => e.message,
              'message',
              '加载页图失败（第 2 页）',
            ),
          ),
        );
        expect(clipboard.writes, isEmpty);
      },
    );

    test('throws load failure and does not write clipboard when page bytes missing', () async {
      final _FakePageBytesLoader loader = _FakePageBytesLoader(pageBytes: null);
      final _FakeClipboardImagePort clipboard = _FakeClipboardImagePort();
      final CopyPageImageService subject = _subject(
        loader: loader,
        clipboard: clipboard,
        encodePng: (_) async => _encodedPng(),
      );

      await expectLater(
        () => subject.execute(comic: _comic(), archivePageIndex: 0),
        throwsA(isA<CopyPageImageException>()),
      );
      expect(clipboard.writes, isEmpty);
    });

    test(
      'throws encode failure and does not write clipboard when encode fails',
      () async {
        final _FakePageBytesLoader loader = _FakePageBytesLoader(
          pageBytes: _sourceBytes(),
        );
        final _FakeClipboardImagePort clipboard = _FakeClipboardImagePort();
        final CopyPageImageService subject = _subject(
          loader: loader,
          clipboard: clipboard,
          encodePng: (_) async => throw StateError('bad image'),
        );

        await expectLater(
          () => subject.execute(comic: _comic(), archivePageIndex: 0),
          throwsA(
            isA<CopyPageImageException>().having(
              (CopyPageImageException e) => e.message,
              'message',
              '转换页图失败（第 1 页）',
            ),
          ),
        );
        expect(clipboard.writes, isEmpty);
      },
    );

    test('throws clipboard failure after PNG encode', () async {
      final _FakePageBytesLoader loader = _FakePageBytesLoader(
        pageBytes: _sourceBytes(),
      );
      final _FakeClipboardImagePort clipboard = _FakeClipboardImagePort(
        error: StateError('clipboard unavailable'),
      );
      final CopyPageImageService subject = _subject(
        loader: loader,
        clipboard: clipboard,
        encodePng: (_) async => _encodedPng(),
      );

      await expectLater(
        () => subject.execute(comic: _comic(), archivePageIndex: 2),
        throwsA(
          isA<CopyPageImageException>().having(
            (CopyPageImageException e) => e.message,
            'message',
            '写入剪贴板失败（第 3 页）',
          ),
        ),
      );
      expect(clipboard.writes, isEmpty);
    });
  });
}
