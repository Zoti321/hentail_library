import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/reading/read_session_exceptions.dart';
import 'package:hentai_library/ui/features/reader/module/widgets/viewport/reader_viewport_pages.dart';
import 'package:hentai_library/ui/features/reader/view_models/read_session_page_data.dart';

void main() {
  group('resolveReaderViewportPages', () {
    test('loading stays loading instead of empty list', () {
      const AsyncValue<List<ReaderPageImageData>> async =
          AsyncLoading<List<ReaderPageImageData>>();
      expect(
        resolveReaderViewportPages(async),
        isA<ReaderViewportPagesLoading>(),
      );
    });

    test('error surfaces explicit viewport error', () {
      final AsyncValue<List<ReaderPageImageData>> async =
          AsyncError<List<ReaderPageImageData>>(
            ReadSessionPageLoadException.loadFailed(
              comicId: 'c1',
              path: '/tmp',
              cause: StateError('boom'),
            ),
            StackTrace.current,
          );
      final ReaderViewportPages resolved = resolveReaderViewportPages(async);
      expect(resolved, isA<ReaderViewportPagesError>());
    });

    test('empty data is empty feedback', () {
      const AsyncValue<List<ReaderPageImageData>> async =
          AsyncData<List<ReaderPageImageData>>(<ReaderPageImageData>[]);
      expect(
        resolveReaderViewportPages(async),
        isA<ReaderViewportPagesEmpty>(),
      );
    });

    test('ready returns pages', () {
      final List<ReaderPageImageData> pages = <ReaderPageImageData>[
        ReaderDirPageImageData(File('/tmp/a.jpg'), pageIndex: 0),
      ];
      final AsyncValue<List<ReaderPageImageData>> async =
          AsyncData<List<ReaderPageImageData>>(pages);
      final ReaderViewportPages resolved = resolveReaderViewportPages(async);
      expect(
        resolved,
        isA<ReaderViewportPagesReady>().having(
          (ReaderViewportPagesReady r) => r.pages,
          'pages',
          pages,
        ),
      );
    });
  });
}
