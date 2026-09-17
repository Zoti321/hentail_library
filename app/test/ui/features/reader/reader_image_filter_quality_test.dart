import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/element/image/app_comic_image.dart';
import 'package:hentai_library/ui/features/reader/module/widgets/viewport/reader_image_filter_quality.dart';
import 'package:hentai_library/ui/features/reader/view_models/read_session_page_data.dart';
import 'package:hentai_library/ui/features/reader/views/reader_page/widgets/reader_image_item.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 1x1 RGBA PNG——让 dir 分支拿到「存在且非空」的真实文件。
const List<int> _onePixelPng = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, //
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, //
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, //
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, //
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, //
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, //
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, //
  0x42, 0x60, 0x82, //
];

Comic _comic() {
  final DateTime now = DateTime.utc(2026, 1, 1);
  return Comic(
    comicId: 'filter-quality-fidelity',
    path: '/tmp/comic',
    resourceType: ResourceType.dir,
    resourceSize: 1024,
    createdAt: now,
    lastUpdatedAt: now,
    title: 'Test',
    pageCount: 1,
  );
}

void main() {
  group('kReaderPageFilterQuality', () {
    test('stays medium — Page image fidelity, never FilterQuality.high', () {
      // high (bicubic, no mipmaps) causes screentone moiré after downscale;
      // scroll-based medium→high settle was the delayed-grid regression.
      expect(kReaderPageFilterQuality, FilterQuality.medium);
      expect(kReaderPageFilterQuality, isNot(FilterQuality.high));
      expect(kReaderPageFilterQuality, isNot(FilterQuality.low));
      expect(kReaderPageFilterQuality, isNot(FilterQuality.none));
    });
  });

  testWidgets(
    'ReaderImageItem always paints AppComicImage at kReaderPageFilterQuality',
    (WidgetTester tester) async {
      final Directory dir = Directory.systemTemp.createTempSync(
        'reader-filter-quality',
      );
      addTearDown(() => dir.deleteSync(recursive: true));
      final File page = File('${dir.path}/page-0.png')
        ..writeAsBytesSync(_onePixelPng);

      await tester.pumpWidget(
        _host(ReaderDirPageImageData(page, pageIndex: 0)),
      );
      await tester.pump();

      final AppComicImage image = tester.widget(find.byType(AppComicImage));
      expect(image.filterQuality, kReaderPageFilterQuality);
      expect(image.filterQuality, FilterQuality.medium);
    },
  );

  testWidgets('ReaderImageItem skips the image for a missing dir page', (
    WidgetTester tester,
  ) async {
    // 缺失路径交给 ExtendedImage 会卡在 LoadState.loading，故 dir 分支直接出错位图。
    await tester.pumpWidget(
      _host(
        ReaderDirPageImageData(
          File('/definitely/missing/reader-filter-quality.png'),
          pageIndex: 0,
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(AppComicImage), findsNothing);
  });
}

Widget _host(ReaderDirPageImageData imageData) {
  return ProviderScope(
    child: MaterialApp(
      locale: const Locale('zh'),
      theme: buildAppTheme(Brightness.light),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ReaderImageItem(
          comic: _comic(),
          imageData: imageData,
          slotLogicalWidth: 400,
        ),
      ),
    ),
  );
}
