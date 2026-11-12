import 'package:hentai_library/features/reader/public.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('public barrel exports ports, factories, routing, page, and bootstrap hooks', () {
    expect(NativeReaderPort, isNotNull);
    expect(ReadingMode, isNotNull);
    expect(createNativeReaderPort, isNotNull);
    expect(createComicPageSourcePort, isNotNull);
    expect(ReaderPage, isNotNull);
    expect(ReaderRouteArgs, isNotNull);
    expect(openReader, isNotNull);
    expect(readerChromeNotifierProvider, isNotNull);
  });
}
