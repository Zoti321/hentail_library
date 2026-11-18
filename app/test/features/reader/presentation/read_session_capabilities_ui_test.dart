import 'package:hentai_library/features/reader/domain/read_session_capabilities.dart';
import 'package:hentai_library/features/reader/presentation/routing/reader_route_context.dart';
import 'package:test/test.dart';

void main() {
  test('Image set route context exposes pop exit and no Comic-only slots', () {
    final ReaderRouteContext route = ReaderRouteContext.imageSet(
      libraryId: 'lib',
      imageSetId: 'set',
      startIndex: 0,
    );
    expect(route.capabilities.exitPolicy, ReadSessionExitPolicy.popRoute);
    expect(route.capabilities.persistProgress, isFalse);
    expect(route.capabilities.seriesNavigation, isFalse);
    expect(route.capabilities.coverActions, isFalse);
    expect(route.sessionOrNull, isNull);
  });

  test('Comic route context keeps go-router exit and progress', () {
    final ReaderRouteContext route = ReaderRouteContext.normalize(
      comicId: 'c1',
    );
    expect(route.capabilities.exitPolicy, ReadSessionExitPolicy.goToComicDetail);
    expect(route.capabilities.persistProgress, isTrue);
    expect(route.sessionOrNull?.comicId, 'c1');
  });
}
