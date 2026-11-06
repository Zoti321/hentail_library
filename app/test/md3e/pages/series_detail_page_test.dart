import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/series/presentation/views/series_detail/series_detail_page_lab_host.dart';

import '../../../widgetbook/preview/md3e_series_detail_page_preview_data.dart';

import '../../support/pump_app.dart';

void main() {
  testWidgets('shows series title and first comic card', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1024, 900));
    await pumpApp(
      tester,
      home: Center(
        child: SizedBox(
          width: 1024,
          height: 900,
          child: SeriesDetailPageLabHost(
            entry: SeriesDetailPagePreviewData.sample(),
          ),
        ),
      ),
    );
    expect(find.text('葬送的芙莉莲'), findsOneWidget);
    expect(find.text('葬送的芙莉莲 第 1 卷'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('external paging renders entry comics without slicing', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1024, 900));
    await pumpApp(
      tester,
      home: Center(
        child: SizedBox(
          width: 1024,
          height: 900,
          child: SeriesDetailLayout(
            entry: const SeriesDetailViewObject(
              title: '外部分页系列',
              comics: <SeriesDetailComicItem>[
                SeriesDetailComicItem(title: '甲卷'),
                SeriesDetailComicItem(title: '乙卷'),
                SeriesDetailComicItem(title: '丙卷'),
              ],
            ),
            page: 2,
            pageSize: 2,
            totalPages: 2,
            onPageChanged: (_) {},
            onPageSizeChanged: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('甲卷'), findsOneWidget);
    expect(find.text('乙卷'), findsOneWidget);
    expect(find.text('丙卷'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });
}
