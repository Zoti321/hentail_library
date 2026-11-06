import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../widgetbook/preview/md3e_series_detail_page_preview_data.dart';

import 'package:hentai_library/features/series/presentation/views/metadata_edit/series_metadata_edit_page.dart';

import '../../support/pump_app.dart';

void main() {
  testWidgets('shows edit series title', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(520, 640));
    await pumpApp(
      tester,
      home: SizedBox(
        width: 520,
        height: 640,
        child: SeriesMetadataEditLayout(
          initialDraft: SeriesMetadataEditDraft.fromEntry(
            SeriesDetailPagePreviewData.sample(),
          ),
        ),
      ),
    );
    expect(find.text('编辑系列'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });
}
