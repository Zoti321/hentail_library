import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_page_comics_providers.dart';
import 'package:hentai_library/features/comic/presentation/views/bulk_edit/bulk_edit_metadata_form.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/ui/patterns/metadata_edit/metadata_field_label_row.dart';
import 'package:hentai_library/shared/ui/widgets/inputs/outlined_text_field.dart';
import 'package:hentai_library/shared/ui/widgets/inputs/tag_input_field.dart';
import 'package:hentai_library/shared/ui/widgets/selection/segmented_capsule_bar.dart';
import 'package:riverpod/misc.dart' show Override;

import '../../../../../support/pump_app.dart';

Comic _comic(String id) {
  return Comic(
    comicId: id,
    path: '/comics/$id',
    resourceType: ResourceType.dir,
    resourceSize: 0,
    createdAt: DateTime.utc(2024),
    lastUpdatedAt: DateTime.utc(2024),
    title: id,
    pageCount: 1,
  );
}

Future<void> _pumpForm(WidgetTester tester, List<String> ids) async {
  final List<Comic> comics = ids.map(_comic).toList(growable: false);
  final List<Override> overrides = <Override>[
    bulkEditComicsByIdsProvider.overrideWith(
      (Ref ref, List<String> _) async => comics,
    ),
  ];
  await pumpApp(
    tester,
    home: ProviderScope(
      overrides: overrides,
      child: Scaffold(
        body: SizedBox(
          height: 480,
          width: 800,
          child: BulkEditMetadataForm(comicIds: ids),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('general tab shows description editor and no tag input', (
    WidgetTester tester,
  ) async {
    await _pumpForm(tester, const <String>['c1', 'c2']);

    expect(find.byType(SegmentedCapsuleBar), findsWidgets);
    expect(find.byType(OutlinedTextField), findsWidgets);
    expect(find.byType(TagInputField), findsOneWidget);
    expect(find.byType(MetadataFieldLabelRow), findsWidgets);
  });

  testWidgets('switching to authors and tags tab hides general editors', (
    WidgetTester tester,
  ) async {
    await _pumpForm(tester, const <String>['c1', 'c2']);

    await tester.tap(find.text('作者&标签'));
    await tester.pumpAndSettle();

    expect(find.byType(OutlinedTextField), findsNothing);
    expect(find.byType(TagInputField), findsWidgets);
  });
}
