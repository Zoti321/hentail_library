import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/pages/md3e_comic_detail_page.dart';

import '../../support/pump_md3e_app.dart';

void main() {
  testWidgets('shows title and read actions', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1024, 800));
    await pumpMd3eApp(
      tester,
      home: Center(
        child: SizedBox(
          width: 1024,
          height: 800,
          child: Md3eComicDetailPage(
            entry: Md3eComicDetailPagePreviewData.sample(),
          ),
        ),
      ),
    );
    expect(find.text('葬送的芙莉莲'), findsOneWidget);
    expect(find.text('阅读'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });
}
