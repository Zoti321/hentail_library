import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/pages/md3e_comic_detail_page.dart';
import 'package:hentai_library/md3e/pages/md3e_library_browse_page.dart';
import 'package:hentai_library/md3e/pages/md3e_series_detail_page.dart';
import 'package:hentai_library/md3e/pages/md3e_reader_page_lab_host.dart';
import 'package:hentai_library/md3e/patterns/library/md3e_lab_catalog_navigation.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/md3e/widgets/actions/md3e_catalog_view_mode_button_group.dart';

import '../../../support/pump_md3e_app.dart';

void main() {
  testWidgets('目录卡片点击按 index 打开对应漫画详情标题', (WidgetTester tester) async {
    await pumpMd3eApp(
      tester,
      home: Scaffold(
        body: Md3eLibraryBrowsePage(
          displayTarget: LibraryDisplayTarget.comics,
          viewMode: Md3eCatalogViewMode.grid,
          filterSortActive: false,
          itemCount: 3,
          totalPages: 1,
          onCatalogItemTap: (int index) {
            openMd3eLabCatalogDetail(
              tester.element(find.byType(Md3eLibraryBrowsePage)),
              displayTarget: LibraryDisplayTarget.comics,
              catalogIndex: index,
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('示例本子 2'));
    await tester.pumpAndSettle();

    expect(find.byType(Md3eComicDetailPage), findsOneWidget);
    expect(find.text('示例本子 2'), findsWidgets);
  });

  testWidgets('漫画详情阅读进入 Reader LabHost', (WidgetTester tester) async {
    await pumpMd3eApp(
      tester,
      home: Scaffold(
        body: Md3eLibraryBrowsePage(
          displayTarget: LibraryDisplayTarget.comics,
          viewMode: Md3eCatalogViewMode.grid,
          filterSortActive: false,
          itemCount: 3,
          totalPages: 1,
          onCatalogItemTap: (int index) {
            openMd3eLabCatalogDetail(
              tester.element(find.byType(Md3eLibraryBrowsePage)),
              displayTarget: LibraryDisplayTarget.comics,
              catalogIndex: index,
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('示例本子 2'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('阅读'));
    await tester.pumpAndSettle();

    expect(find.byType(Md3eReaderPageLabHost), findsOneWidget);
    expect(find.text('示例本子 2'), findsWidgets);
  });

  testWidgets('系列目录 index 打开系列详情标题', (WidgetTester tester) async {
    await pumpMd3eApp(
      tester,
      home: Scaffold(
        body: Md3eLibraryBrowsePage(
          displayTarget: LibraryDisplayTarget.series,
          viewMode: Md3eCatalogViewMode.grid,
          filterSortActive: false,
          itemCount: 2,
          totalPages: 1,
          onCatalogItemTap: (int index) {
            openMd3eLabCatalogDetail(
              tester.element(find.byType(Md3eLibraryBrowsePage)),
              displayTarget: LibraryDisplayTarget.series,
              catalogIndex: index,
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('示例系列 1'));
    await tester.pumpAndSettle();

    expect(find.byType(Md3eSeriesDetailPage), findsOneWidget);
    expect(find.text('示例系列 1'), findsWidgets);
  });
}
