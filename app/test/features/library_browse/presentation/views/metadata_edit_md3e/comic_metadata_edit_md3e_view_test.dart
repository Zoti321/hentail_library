import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/library_browse/presentation/views/metadata_edit_md3e/comic_metadata_edit_md3e_page.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';

import '../../../../../support/pump_localized_app.dart';

void main() {
  testWidgets(
    'comic metadata edit view shows fields without AnimatedSwitcher',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final DateTime now = DateTime.utc(2026, 1, 1);
      await pumpLocalizedApp(
        tester,
        wrapProviderScope: true,
        home: Scaffold(
          body: ComicMetadataEditMd3eView(
            comic: Comic(
              comicId: 'c1',
              path: '/tmp/c1.cbz',
              resourceType: ResourceType.cbz,
              resourceSize: 1,
              createdAt: now,
              lastUpdatedAt: now,
              title: 'Title',
              pageCount: 1,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(AnimatedSwitcher), findsNothing);
      expect(find.text('Title'), findsOneWidget);
    },
  );
}
