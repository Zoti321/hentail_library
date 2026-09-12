import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/edit_metadata_dialog.dart';

import '../../../../../support/pump_localized_app.dart';

void main() {
  testWidgets('edit metadata dialog tab pane swaps without AnimatedSwitcher', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final DateTime now = DateTime.utc(2026, 1, 1);
    await pumpLocalizedApp(
      tester,
      wrapProviderScope: true,
      home: Scaffold(
        body: EditMetadataDialog(
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
          onSave: (_) async {},
          seriesItemSort: (
            seriesId: 's1',
            sortOrder: 1,
            sortOrderLocked: false,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(AnimatedSwitcher), findsNothing);
    expect(find.text('Title'), findsOneWidget);
  });
}
