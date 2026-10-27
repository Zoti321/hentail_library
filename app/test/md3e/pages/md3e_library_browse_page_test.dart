import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/md3e/pages/md3e_library_browse_page.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/md3e/patterns/library/md3e_library_page_header.dart';
import 'package:hentai_library/md3e/widgets/actions/md3e_catalog_view_mode_button_group.dart';

import '../../support/pump_md3e_app.dart';

void main() {
  testWidgets('library browse page shows header and view toggle', (
    WidgetTester tester,
  ) async {
    await pumpMd3eApp(
      tester,
      home: Scaffold(
        body: Md3eLibraryBrowsePage(
          displayTarget: LibraryDisplayTarget.comics,
          viewMode: Md3eCatalogViewMode.grid,
          filterSortActive: false,
          totalPages: 3,
          onDisplayTargetChanged: (_) {},
          onViewModeChanged: (_) {},
          onPageChanged: (_) {},
        ),
      ),
    );

    expect(find.text('漫画库'), findsOneWidget);
    expect(find.text('1284 本'), findsOneWidget);
    expect(find.byType(Md3eCatalogViewModeButtonGroup), findsOneWidget);
  });
}
