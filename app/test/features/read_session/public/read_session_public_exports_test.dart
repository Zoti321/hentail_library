import 'package:hentai_library/features/read_session/public.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('public barrel exports ports, factories, routing, page, and bootstrap hooks', () {
    expect(ReadSessionLaunchPort, isNotNull);
    expect(ReaderSessionPort, isNotNull);
    expect(ReadingMode, isNotNull);
    expect(createReadSessionLaunchPort, isNotNull);
    expect(createReaderSessionPort, isNotNull);
    expect(createComicPageSourcePort, isNotNull);
    expect(ReaderMd3ePage, isNotNull);
    expect(ReaderRouteArgs, isNotNull);
    expect(openReadSession, isNotNull);
    expect(readerFullscreenControllerProvider, isNotNull);
    expect(comicImagesProvider, isNotNull);
  });
}
