import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/pages/md3e_home_page.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_page_copy.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_library_management_copy.dart';

import '../../support/pump_md3e_app.dart';

void main() {
  testWidgets('shows library management section with preview rows', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 900));
    await pumpMd3eApp(
      tester,
      home: SizedBox(
        width: 900,
        height: 900,
        child: Md3eHomePage(
          onAddLocalLibrary: () {},
          onAddRemoteLibrary: () {},
        ),
      ),
    );

    expect(find.text(Md3eHomePageCopy.aggregateStatsSectionTitle), findsOneWidget);
    expect(find.textContaining('2552'), findsOneWidget);
    expect(find.text(Md3eHomeLibraryManagementCopy.sectionTitle), findsOneWidget);
    expect(find.text('本机漫画'), findsOneWidget);
    expect(find.text('NAS WebDAV'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });
}
