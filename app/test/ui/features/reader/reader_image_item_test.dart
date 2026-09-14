import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/reading/reader_page_payload.dart';
import 'package:hentai_library/ui/features/reader/view_models/read_session_page_data.dart';
import 'package:hentai_library/ui/features/reader/view_models/read_session_providers.dart';
import 'package:hentai_library/ui/features/reader/views/reader_page/widgets/reader_image_item.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:riverpod/misc.dart' show Override;

import '../../../support/pump_localized_app.dart';

Comic _comic({required String comicId, ResourceType type = ResourceType.zip}) {
  final DateTime now = DateTime.utc(2026, 1, 1);
  return Comic(
    comicId: comicId,
    path: '/tmp/comic',
    resourceType: type,
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

    await pumpLocalizedApp(
      tester,
      wrapProviderScope: true,
      overrides: <Override>[
        comicReaderPageProvider(
          comicId: comicId,
          pageIndex: pageIndex,
        ).overrideWith(
          (Ref ref) async =>
              const ReaderPageFilePath('/definitely/missing/reader-page.jpg'),
        ),
      ],
      home: Scaffold(
        body: ReaderImageItem(
          comic: _comic(comicId: comicId),
          imageData: imageData,
          slotLogicalWidth: 400,
        ),
      ),
    );
    await tester.pump();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(errors, isEmpty);
  });

  testWidgets('directory page missing file shows error placeholder', (
    WidgetTester tester,
  ) async {
    const String comicId = 'reader-dir-missing';
    final ReaderDirPageImageData imageData = ReaderDirPageImageData(
      File('/definitely/missing/dir-page.jpg'),
      pageIndex: 0,
    );

    await pumpLocalizedApp(
      tester,
      wrapProviderScope: true,
      home: Scaffold(
        body: ReaderImageItem(
          comic: _comic(comicId: comicId, type: ResourceType.dir),
          imageData: imageData,
          slotLogicalWidth: 400,
        ),
      ),
    );
    await tester.pump();

    expect(find.byIcon(LucideIcons.bookImage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
