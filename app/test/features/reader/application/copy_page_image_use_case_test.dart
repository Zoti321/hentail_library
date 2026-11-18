import 'dart:typed_data';

import 'package:hentai_library/features/reader/domain/clipboard_image_port.dart';
import 'package:hentai_library/features/reader/application/copy_page_image_use_case.dart';
import 'package:test/test.dart';

class _FakePageBytesLoader {
  _FakePageBytesLoader({this.pageBytes, this.error});

  final Uint8List? pageBytes;
  final Object? error;
  final List<({String sessionKey, int archivePageIndex})> requests =
      <({String sessionKey, int archivePageIndex})>[];

  Future<Uint8List?> call({
    required String sessionKey,
    required int archivePageIndex,
  }) async {
    requests.add((sessionKey: sessionKey, archivePageIndex: archivePageIndex));
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

CopyPageImageUseCase _subject({
  required _FakePageBytesLoader loader,
  required _FakeClipboardImagePort clipboard,
  required PageImagePngEncoder encodePng,
}) {
  return CopyPageImageUseCase(
    loadPageBytes: loader.call,
    clipboardImage: clipboard,
    encodePng: encodePng,
  );
}

void main() {
  group('CopyPageImageUseCase', () {
    test('loads requested page bytes, encodes PNG, writes clipboard', () async {
      final _FakePageBytesLoader loader = _FakePageBytesLoader(
        pageBytes: _sourceBytes(),
      );
      final _FakeClipboardImagePort clipboard = _FakeClipboardImagePort();
      final List<Uint8List> encodedInputs = <Uint8List>[];
      final CopyPageImageUseCase subject = _subject(
        loader: loader,
        clipboard: clipboard,
        encodePng: (Uint8List bytes) async {
          encodedInputs.add(bytes);
          return _encodedPng();
        },
      );

      await subject.execute(sessionKey: 'c1', archivePageIndex: 4);

      expect(loader.requests.single.archivePageIndex, 4);
      expect(loader.requests.single.sessionKey, 'c1');
      expect(encodedInputs, <Uint8List>[_sourceBytes()]);
      expect(clipboard.writes, <Uint8List>[_encodedPng()]);
    });

    test('uses the supplied session key for Image set sessions', () async {
      const String sessionKey = 'image_set:lib:set';
      final _FakePageBytesLoader loader = _FakePageBytesLoader(
        pageBytes: _sourceBytes(),
      );
      final CopyPageImageUseCase subject = _subject(
        loader: loader,
        clipboard: _FakeClipboardImagePort(),
        encodePng: (Uint8List bytes) async => _encodedPng(),
      );

      await subject.execute(sessionKey: sessionKey, archivePageIndex: 0);

      expect(loader.requests.single.sessionKey, sessionKey);
    });

    test('wraps empty page bytes as loadFailed', () async {
      final CopyPageImageUseCase subject = _subject(
        loader: _FakePageBytesLoader(pageBytes: Uint8List(0)),
        clipboard: _FakeClipboardImagePort(),
        encodePng: (Uint8List bytes) async => _encodedPng(),
      );

      await expectLater(
        () => subject.execute(sessionKey: 'c1', archivePageIndex: 1),
        throwsA(isA<CopyPageImageException>()),
      );
    });

    test('wraps loader errors as loadFailed', () async {
      final CopyPageImageUseCase subject = _subject(
        loader: _FakePageBytesLoader(error: StateError('boom')),
        clipboard: _FakeClipboardImagePort(),
        encodePng: (Uint8List bytes) async => _encodedPng(),
      );

      await expectLater(
        () => subject.execute(sessionKey: 'c1', archivePageIndex: 0),
        throwsA(isA<CopyPageImageException>()),
      );
    });

    test('wraps encode errors as encodeFailed', () async {
      final CopyPageImageUseCase subject = _subject(
        loader: _FakePageBytesLoader(pageBytes: _sourceBytes()),
        clipboard: _FakeClipboardImagePort(),
        encodePng: (Uint8List bytes) async => throw StateError('encode'),
      );

      await expectLater(
        () => subject.execute(sessionKey: 'c1', archivePageIndex: 0),
        throwsA(isA<CopyPageImageException>()),
      );
    });

    test('wraps clipboard errors as clipboardWriteFailed', () async {
      final CopyPageImageUseCase subject = _subject(
        loader: _FakePageBytesLoader(pageBytes: _sourceBytes()),
        clipboard: _FakeClipboardImagePort(error: StateError('clip')),
        encodePng: (Uint8List bytes) async => _encodedPng(),
      );

      await expectLater(
        () => subject.execute(sessionKey: 'c1', archivePageIndex: 2),
        throwsA(isA<CopyPageImageException>()),
      );
    });
  });
}
