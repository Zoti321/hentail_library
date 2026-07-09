import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/reading/reader_page_payload.dart';
import 'package:hentai_library/ui/features/reader/view_models/read_session_page_data.dart';
import 'package:hentai_library/ui/features/reader/view_models/read_session_providers.dart';
import 'package:hentai_library/ui/features/reader/views/reader_page/widgets/reader_image_item.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;

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
        child: const MaterialApp(
          home: Scaffold(
            body: ReaderImageItem(imageData: imageData, slotLogicalWidth: 400),
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
