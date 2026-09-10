import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/ports/clipboard_image_port.dart';
import 'package:hentai_library/domain/ports/comic_page_source_port.dart';
import 'package:hentai_library/domain/reading/page_image_copy.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/features/reader/view_models/page_image_copy_provider.dart';
import 'package:hentai_library/ui/features/reader/view_models/read_session_page_data.dart';
import 'package:hentai_library/ui/features/reader/views/reader_page/widgets/reader_image_item.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;

class _SpyPageImageCopy extends PageImageCopy {
  _SpyPageImageCopy(this.calls)
    : super(
        pageSource: _UnusedComicPageSourcePort(),
        clipboardImage: _UnusedClipboardImagePort(),
      );

  final List<({String comicId, int pageIndex})> calls;

  @override
  Future<void> execute({
    required Comic comic,
    required int archivePageIndex,
  }) async {
    calls.add((comicId: comic.comicId, pageIndex: archivePageIndex));
  }
}

class _UnusedComicPageSourcePort implements ComicPageSourcePort {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedClipboardImagePort implements ClipboardImagePort {
  @override
  Future<void> writePng(Uint8List pngBytes) async {}
}

Comic _comic() {
  final DateTime now = DateTime.utc(2026, 1, 1);
  return Comic(
    comicId: 'c1',
    path: '/tmp/comic',
    resourceType: ResourceType.dir,
    resourceSize: 1024,
    createdAt: now,
    lastUpdatedAt: now,
    title: 'Test',
    pageCount: 5,
  );
}

void main() {
  testWidgets('long press opens menu and copies the pressed page image', (
    WidgetTester tester,
  ) async {
    final List<({String comicId, int pageIndex})> calls =
        <({String comicId, int pageIndex})>[];

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          pageImageCopyProvider.overrideWith(
            (Ref ref) => _SpyPageImageCopy(calls),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('zh'),
          theme: buildAppTheme(Brightness.light),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                height: 200,
                // Empty path avoids ExtendedImage async decode timers.
                child: ReaderImageItem(
                  comic: _comic(),
                  imageData: ReaderDirPageImageData(File(''), pageIndex: 3),
                  slotLogicalWidth: 200,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.longPress(find.byType(ReaderImageItem));
    await tester.pump();

    expect(find.text('复制页图'), findsOneWidget);

    await tester.tap(find.text('复制页图'));
    await tester.pump();

    expect(calls, <({String comicId, int pageIndex})>[
      (comicId: 'c1', pageIndex: 3),
    ]);

    // Success toast keeps a dismiss timer; drain it so the suite can finish.
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 300));
  });
}
