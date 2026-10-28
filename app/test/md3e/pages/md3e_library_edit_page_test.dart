import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/pages/md3e_library_edit_page.dart';

import '../../support/pump_md3e_app.dart';

void main() {
  testWidgets('shows edit library title and save action', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 720));
    await pumpMd3eApp(
      tester,
      home: const SizedBox(
        width: 900,
        height: 720,
        child: Md3eLibraryEditPage(
          intent: Md3eLibraryEditPageIntent.editLocal,
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
