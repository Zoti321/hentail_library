import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../widgetbook/preview/md3e_comic_detail_page_preview_data.dart';

import 'package:hentai_library/features/comic/presentation/views/metadata_edit/comic_metadata_edit_page.dart';

import '../../support/pump_app.dart';

void main() {
  testWidgets('shows edit metadata title and save action', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 720));
    await pumpApp(
      tester,
      home: ProviderScope(
        child: SizedBox(
          width: 900,
          height: 720,
          child: ComicMetadataEditLayout(
            initialDraft: ComicMetadataEditDraft.fromEntry(
              ComicDetailPagePreviewData.sample(),
            ),
          ),
        ),
      ),
    );
    expect(find.text('编辑元数据'), findsOneWidget);
    expect(find.text('保存'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });
}
