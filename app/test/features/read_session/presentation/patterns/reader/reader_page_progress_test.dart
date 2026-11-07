import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/read_session/presentation/patterns/reader/reader_page_progress.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../../../support/pump_app.dart';

void main() {
  group('ReaderPageProgress', () {
    testWidgets('onChangeEnd uses last onChanged when callback value is stale', (
      WidgetTester tester,
    ) async {
      int? committedPage;
      await pumpApp(
        tester,
        home: Scaffold(
          body: ReaderPageProgress(
            currentPage: 10,
            totalPages: 100,
            onPageChanged: (int page) => committedPage = page,
          ),
        ),
      );

      final M3ESlider slider = tester.widget(find.byType(M3ESlider));
      slider.onChanged!(50);
      await tester.pump();
      // 模拟 M3E 在父级 rebuild 前用旧 widget.value 调 onChangeEnd。
      slider.onChangeEnd!(10);

      expect(committedPage, 50);
    });
  });
}
