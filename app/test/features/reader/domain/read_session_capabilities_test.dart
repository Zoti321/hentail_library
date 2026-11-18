import 'package:hentai_library/features/reader/domain/read_session_capabilities.dart';
import 'package:hentai_library/features/reader/domain/read_session_source.dart';
import 'package:test/test.dart';

void main() {
  group('ReadSessionCapabilities.from', () {
    test('Comic enables progress, Series, cover, native IO and go-router exit', () {
      final caps = ReadSessionCapabilities.from(
        const ComicReadSessionSource('c1'),
      );
      expect(caps.persistProgress, isTrue);
      expect(caps.seriesNavigation, isTrue);
      expect(caps.coverActions, isTrue);
      expect(caps.nativeSession, isTrue);
      expect(caps.nativePrefetch, isTrue);
      expect(caps.seriesAutoPlayModes, isTrue);
      expect(caps.exitPolicy, ReadSessionExitPolicy.goToComicDetail);
    });

    test('Comic incognito disables progress only', () {
      final caps = ReadSessionCapabilities.from(
        const ComicReadSessionSource('c1'),
        incognito: true,
      );
      expect(caps.persistProgress, isFalse);
      expect(caps.seriesNavigation, isTrue);
      expect(caps.exitPolicy, ReadSessionExitPolicy.goToComicDetail);
    });

    test('Image set disables Comic-only capabilities and pops on exit', () {
      final caps = ReadSessionCapabilities.from(
        const ImageSetReadSessionSource(
          libraryId: 'lib',
          imageSetId: 'set',
          startIndex: 0,
        ),
      );
      expect(caps.persistProgress, isFalse);
      expect(caps.seriesNavigation, isFalse);
      expect(caps.coverActions, isFalse);
      expect(caps.nativeSession, isFalse);
      expect(caps.nativePrefetch, isFalse);
      expect(caps.seriesAutoPlayModes, isFalse);
      expect(caps.exitPolicy, ReadSessionExitPolicy.popRoute);
    });
  });
}
