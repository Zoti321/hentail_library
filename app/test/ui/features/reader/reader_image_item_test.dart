import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/reading/reader_page_payload.dart';
import 'package:hentai_library/ui/features/reader/view_models/read_session_page_data.dart';
import 'package:hentai_library/ui/features/reader/view_models/read_session_providers.dart';
import 'package:hentai_library/ui/features/reader/views/reader_page/widgets/reader_image_item.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;

Comic _comic({required String comicId}) {
  final DateTime now = DateTime.utc(2026, 1, 1);
  return Comic(
    comicId: comicId,
    path: '/tmp/comic',
    resourceType: ResourceType.zip,
    resourceSize: 1024,
    createdAt: now,
    lastUpdatedAt: now,
    title: 'Test',
    pageCount: 1,
  );
}

void main() {
  testWidgets('unmounting before stale archive page reload does not throw', (
    WidgetTester tester,
  ) async {
    final List<FlutterErrorDetails> errors = <FlutterErrorDetails>[];
    final void Function(FlutterErrorDetails details)? previousHandler =
        FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      errors.add(details);
      previousHandler?.call(details);
    };
    addTearDown(() {
      FlutterError.onError = previousHandler;
    });

    const String comicId = 'reader-image-item-test';
    const int pageIndex = 0;
    const ReaderArchivePageImageData imageData = ReaderArchivePageImageData(
      comicId: comicId,
      pageIndex: pageIndex,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          comicReaderPageProvider(
            comicId: comicId,
            pageIndex: pageIndex,
          ).overrideWith(
            (Ref ref) async =>
                const ReaderPageFilePath('/definitely/missing/reader-page.jpg'),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ReaderImageItem(
              comic: _comic(comicId: comicId),
              imageData: imageData,
              slotLogicalWidth: 400,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(errors, isEmpty);
  });
}
