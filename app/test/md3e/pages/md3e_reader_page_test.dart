import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/pages/md3e_reader_page_lab_host.dart';
import 'package:hentai_library/md3e/patterns/reader/md3e_reader_page_copy.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../support/pump_md3e_app.dart';

void main() {
  testWidgets('shows series title, viewport placeholder, and progress slider', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1024, 800));
    await pumpMd3eApp(
      tester,
      home: const SizedBox(
        width: 1024,
        height: 800,
        child: Md3eReaderPageLabHost(),
      ),
    );
    expect(find.text('葬送的芙莉莲'), findsOneWidget);
    expect(find.text('第 01 卷'), findsOneWidget);
    expect(
      find.text(Md3eReaderPageCopy.viewportPlaceholder(3)),
      findsOneWidget,
    );
    expect(find.byType(M3ESlider), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('tap zones paginate when chrome hidden', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1024, 800));
    await pumpMd3eApp(
      tester,
      home: const SizedBox(
        width: 1024,
        height: 800,
        child: Md3eReaderPageLabHost(),
      ),
    );
    await tester.tapAt(const Offset(512, 400));
    await tester.pumpAndSettle();
    expect(find.text(Md3eReaderPageCopy.viewportPlaceholder(3)), findsOneWidget);

    await tester.tapAt(const Offset(900, 400));
    await tester.pumpAndSettle();
    expect(find.text(Md3eReaderPageCopy.viewportPlaceholder(4)), findsOneWidget);

    await tester.tapAt(const Offset(100, 400));
    await tester.pumpAndSettle();
    expect(find.text(Md3eReaderPageCopy.viewportPlaceholder(3)), findsOneWidget);

    await tester.binding.setSurfaceSize(null);
  });
}
