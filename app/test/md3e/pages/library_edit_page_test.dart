import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/library_admin/presentation/views/library/library_edit_page.dart';

import '../../../widgetbook/preview/md3e_library_edit_preview_data.dart';

import '../../support/pump_app.dart';

void main() {
  testWidgets('shows edit library title and save action', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 720));
    await pumpApp(
      tester,
      home: SizedBox(
        width: 900,
        height: 720,
        child: LibraryEditPage(
          intent: LibraryEditPageIntent.editLocal,
          initialForm: LibraryEditPreviewData.editLocalForm(),
        ),
      ),
    );
    expect(find.text('编辑库'), findsOneWidget);
    expect(find.text('保存'), findsOneWidget);
    expect(find.text('常规'), findsOneWidget);
    expect(find.text('浏览'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });
}
