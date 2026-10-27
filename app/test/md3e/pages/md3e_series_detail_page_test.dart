import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/pages/md3e_series_detail_page.dart';

import '../../support/pump_md3e_app.dart';

void main() {
  testWidgets('shows series title and first comic card', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1024, 900));
    await pumpMd3eApp(
      tester,
      home: Center(
        child: SizedBox(
          width: 1024,
          height: 900,
          child: Md3eSeriesDetailPage(
            entry: Md3eSeriesDetailPagePreviewData.sample(),
          ),
        ),
      ),
    );
    expect(find.text('葬送的芙莉莲'), findsOneWidget);
    expect(find.text('葬送的芙莉莲 第 1 卷'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });
}
