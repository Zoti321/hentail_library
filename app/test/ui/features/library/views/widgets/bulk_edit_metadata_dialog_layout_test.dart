import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/repositories/comic_repository.dart';
import 'package:hentai_library/ui/core/widgets/form/tag_library_multi_select_field.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/dialog_side_tab_bar.dart';
import 'package:hentai_library/ui/features/library/views/widgets/bulk_edit_metadata_dialog.dart';
import 'package:hentai_library/ui/features/shell/di/repos.dart';
import 'package:riverpod/misc.dart' show Override;

import '../../../../../support/pump_localized_app.dart';

class _FakeComicRepo implements ComicRepository {
  _FakeComicRepo(this._comics);

  final List<Comic> _comics;

  @override
  Future<List<Comic>> findByIds(List<String> comicIds) async {
    return _comics
        .where((Comic c) => comicIds.contains(c.comicId))
        .toList(growable: false);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Comic _comic(String id, {String title = 'Comic'}) {
  return Comic(
    comicId: id,
    path: '/comics/$id',
    resourceType: ResourceType.dir,
    resourceSize: 0,
    createdAt: DateTime.utc(2024),
    lastUpdatedAt: DateTime.utc(2024),
    title: title,
    pageCount: 1,
  );
}

Future<void> _pumpDialog(
  WidgetTester tester, {
  required Size viewport,
  List<Comic> comics = const <Comic>[],
}) async {
  tester.view.physicalSize = viewport;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final List<Comic> resolved = comics.isEmpty
      ? <Comic>[_comic('c1'), _comic('c2')]
      : comics;

  await pumpLocalizedApp(
    tester,
    wrapProviderScope: true,
    overrides: <Override>[
      comicRepoProvider.overrideWith((Ref ref) => _FakeComicRepo(resolved)),
    ],
    home: Scaffold(
      body: BulkEditMetadataDialog(
        comicIds: resolved.map((Comic c) => c.comicId).toList(growable: false),
      ),
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle();
}

Future<void> _selectFieldRow(WidgetTester tester, String fieldLabel) async {
  final Finder row = find.ancestor(
    of: find.text(fieldLabel),
    matching: find.byType(InkWell),
  );
  await tester.tap(row);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('dialog title uses comic count with middle dot separator', (
    WidgetTester tester,
  ) async {
    await _pumpDialog(tester, viewport: const Size(1200, 800));

    expect(find.text('批量编辑 · 2 本'), findsOneWidget);
  });

  testWidgets('authors tab lists taxonomy fields without general editors', (
    WidgetTester tester,
  ) async {
    await _pumpDialog(tester, viewport: const Size(1200, 800));

    expect(find.byType(DialogSideTabBar), findsOneWidget);
    expect(find.text('作者'), findsNothing);

    await tester.tap(find.text('作者&标签'));
    await tester.pumpAndSettle();

    expect(find.text('标签'), findsWidgets);
    expect(find.text('概要'), findsNothing);
    expect(find.byType(TagLibraryMultiSelectField), findsNothing);
  });

  testWidgets('selected field shows editor without enable toggle', (
    WidgetTester tester,
  ) async {
    await _pumpDialog(tester, viewport: const Size(1200, 800));

    expect(find.text('操作'), findsOneWidget);

    await _selectFieldRow(tester, '发布日期');
    expect(find.text('操作'), findsOneWidget);
  });

  testWidgets('compact layout uses capsule tabs instead of side tabs', (
    WidgetTester tester,
  ) async {
    await _pumpDialog(tester, viewport: const Size(500, 800));

    expect(find.byType(DialogSideTabBar), findsNothing);
    expect(find.text('常规'), findsOneWidget);
  });
}
