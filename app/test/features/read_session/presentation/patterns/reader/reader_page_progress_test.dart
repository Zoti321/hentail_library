import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/read_session/domain/auto_play_interval.dart';
import 'package:hentai_library/features/read_session/presentation/patterns/reader/reader_page_progress.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../../../support/pump_app.dart';

void main() {
  group('ReaderPageProgress', () {
    testWidgets(
      'onChangeEnd uses last onChanged when callback value is stale',
      (WidgetTester tester) async {
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
      },
    );

    testWidgets('uses flat slider when autoplay is off', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        home: Scaffold(
          body: ReaderPageProgress(
            currentPage: 3,
            totalPages: 20,
            onPageChanged: (_) {},
          ),
        ),
      );

      final M3ESlider slider = tester.widget(find.byType(M3ESlider));
      expect(slider.wavy, isFalse);
    });

    testWidgets('uses wavy slider with interval wavelength when autoplay on', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        home: Scaffold(
          body: ReaderPageProgress(
            currentPage: 3,
            totalPages: 20,
            onPageChanged: (_) {},
            autoPlayEnabled: true,
            autoPlayIntervalSeconds: 8,
          ),
        ),
      );

      final M3ESlider slider = tester.widget(find.byType(M3ESlider));
      expect(slider.wavy, isTrue);
      expect(slider.wavelength, readerAutoPlaySliderWavelength(8));
      expect(slider.amplitude, 1);
    });
  });
}
