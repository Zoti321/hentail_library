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
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('zh'),
            theme: buildAppTheme(Brightness.light),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: ReaderImageItem(
                comic: _comic(),
                // Non-empty missing path still builds AppComicImage (decode may fail).
                imageData: ReaderDirPageImageData(
                  File('/definitely/missing/reader-filter-quality.jpg'),
                  pageIndex: 0,
                ),
                slotLogicalWidth: 400,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final AppComicImage image = tester.widget(find.byType(AppComicImage));
      expect(image.filterQuality, kReaderPageFilterQuality);
      expect(image.filterQuality, FilterQuality.medium);
    },
  );
}
