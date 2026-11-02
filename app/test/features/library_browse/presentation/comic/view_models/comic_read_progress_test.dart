import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/library_browse/presentation/comic/view_models/comic_read_progress.dart';

void main() {
  test('comicReadProgressFor returns null without a reading record', () {
    expect(comicReadProgressFor(pageIndex: null, pageCount: 20), isNull);
  });

  test('comicReadProgressFor returns null when page count is invalid', () {
    expect(comicReadProgressFor(pageIndex: 3, pageCount: 0), isNull);
  });

  test('comicReadProgressFor maps 1-based page to ratio', () {
    expect(comicReadProgressFor(pageIndex: 5, pageCount: 20), 0.25);
    expect(comicReadProgressFor(pageIndex: 20, pageCount: 20), 1.0);
  });

  test('comicReadProgressFor clamps overshooting page index', () {
    expect(comicReadProgressFor(pageIndex: 30, pageCount: 20), 1.0);
  });
}
