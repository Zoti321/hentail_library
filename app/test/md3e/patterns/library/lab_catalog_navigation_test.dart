import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/comic/presentation/views/comic_detail/comic_detail_page.dart';

import '../../../../widgetbook/lab/pages/library_browse_page.dart';

import 'package:hentai_library/features/series/presentation/views/series_detail/series_detail_page.dart';

import '../../../../widgetbook/hosts/md3e_reader_page_lab_host.dart';
import '../../../../widgetbook/lab/navigation/md3e_lab_catalog_navigation.dart';

import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/ui/widgets/actions/catalog_view_mode_button_group.dart';

import '../../../support/pump_app.dart';

void main() {
  testWidgets('目录卡片点击按 index 打开对应漫画详情标题', (WidgetTester tester) async {
    await pumpApp(
      tester,
      home: Scaffold(
        body: LibraryBrowseLayout(
          displayTarget: LibraryDisplayTarget.comics,
          viewMode: CatalogViewMode.grid,
          filterSortActive: false,
          itemCount: 3,
          totalPages: 1,
          onCatalogItemTap: (int index) {
            openLabCatalogDetail(
              tester.element(find.byType(LibraryBrowseLayout)),
              displayTarget: LibraryDisplayTarget.comics,
              catalogIndex: index,
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('示例本子 2'));
    await tester.pumpAndSettle();

    expect(find.byType(ComicDetailLayout), findsOneWidget);
    expect(find.text('示例本子 2'), findsWidgets);
  });

  testWidgets('漫画详情阅读进入 Reader LabHost', (WidgetTester tester) async {
    await pumpApp(
      tester,
      home: Scaffold(
        body: LibraryBrowseLayout(
          displayTarget: LibraryDisplayTarget.comics,
          viewMode: CatalogViewMode.grid,
          filterSortActive: false,
          itemCount: 3,
          totalPages: 1,
          onCatalogItemTap: (int index) {
            openLabCatalogDetail(
              tester.element(find.byType(LibraryBrowseLayout)),
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

    expect(find.byType(ReaderPageLabHost), findsOneWidget);
    expect(find.text('示例本子 2'), findsWidgets);
  });

  testWidgets('系列目录 index 打开系列详情标题', (WidgetTester tester) async {
    await pumpApp(
      tester,
      home: Scaffold(
        body: LibraryBrowseLayout(
          displayTarget: LibraryDisplayTarget.series,
          viewMode: CatalogViewMode.grid,
          filterSortActive: false,
          itemCount: 2,
          totalPages: 1,
          onCatalogItemTap: (int index) {
            openLabCatalogDetail(
              tester.element(find.byType(LibraryBrowseLayout)),
              displayTarget: LibraryDisplayTarget.series,
              catalogIndex: index,
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('示例系列 1'));
    await tester.pumpAndSettle();

    expect(find.byType(SeriesDetailLayout), findsOneWidget);
    expect(find.text('示例系列 1'), findsWidgets);
  });
}
