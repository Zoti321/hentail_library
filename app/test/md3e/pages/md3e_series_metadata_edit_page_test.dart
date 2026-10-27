import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/pages/md3e_series_metadata_edit_page.dart';

import '../../support/pump_md3e_app.dart';

void main() {
  testWidgets('shows edit series title', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(520, 640));
    await pumpMd3eApp(
      tester,
      home: const SizedBox(
        width: 520,
        height: 640,
        child: Md3eSeriesMetadataEditPage(),
      ),
    );
    expect(find.text('编辑系列'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });
}
