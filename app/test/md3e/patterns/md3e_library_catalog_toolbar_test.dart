import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/patterns/md3e_library_catalog_toolbar.dart';
import 'package:hentai_library/md3e/patterns/md3e_library_page_header.dart';

import '../../support/pump_md3e_app.dart';

void main() {
  testWidgets('shows series count when display target is series', (
    WidgetTester tester,
  ) async {
    await pumpMd3eApp(
      tester,
      home: Center(
        child: Md3eLibraryCatalogToolbar(
          displayTarget: Md3eLibraryDisplayTarget.series,
          comicCount: 10,
          seriesCount: 96,
          onDisplayTargetChanged: (_) {},
        ),
      ),
    );

    expect(find.text('96 个系列'), findsOneWidget);
    expect(find.text('10 本'), findsNothing);
  });
}
