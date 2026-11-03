import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/home/presentation/views/home_md3e/md3e_home_page.dart';
import 'package:hentai_library/features/home/presentation/views/home_md3e/patterns/md3e_home_page_copy.dart';
import 'package:hentai_library/features/library_admin/presentation/views/home_library_dashboard/patterns/md3e_home_library_management_copy.dart';
import 'package:hentai_library/features/library_admin/presentation/views/home_library_dashboard/patterns/md3e_home_library_management_section.dart';

import '../../../../../../widgetbook/preview/md3e_home_page_preview_data.dart';
import '../../../../../support/pump_md3e_app.dart';

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
          aggregateCounts: Md3eHomePagePreviewData.sampleAggregateCounts(),
          libraryManagementSection: Md3eHomeLibraryManagementSection(
            libraries: Md3eHomePagePreviewData.sampleLibraries(),
            onAddLocalLibrary: () {},
            onAddRemoteLibrary: () {},
          ),
        ),
      ),
    );

    expect(
      find.text(Md3eHomePageCopy.aggregateStatsSectionTitle),
      findsOneWidget,
    );
    expect(find.textContaining('2552'), findsOneWidget);
    expect(
      find.text(Md3eHomeLibraryManagementCopy.sectionTitle),
      findsOneWidget,
    );
    expect(find.text('本机漫画'), findsOneWidget);
    expect(find.text('NAS WebDAV'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });
}
