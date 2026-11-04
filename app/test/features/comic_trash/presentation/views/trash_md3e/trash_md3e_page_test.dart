import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/comic_trash/presentation/views/trash_md3e/trash_md3e_page.dart';
import 'package:hentai_library/features/library_browse/public.dart';
import 'package:hentai_library/shared/di/data_providers.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/features/comic_trash/domain/trashed_comic.dart';
import 'package:hentai_library/shared/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/shared/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/shared/domain/ports/comic_trash_reader_session_port.dart';
import 'package:hentai_library/shared/domain/ports/library_revision_port.dart';
import 'package:hentai_library/features/comic_trash/domain/comic_trash_repository.dart';
import 'package:hentai_library/shared/ui/models/comic_cover_state.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:riverpod/misc.dart' show Override;

import '../../../../../support/pump_localized_app.dart';

class _FakeLibraryRevisionPort implements LibraryRevisionPort {
  final StreamController<void> events = StreamController<void>.broadcast();

  @override
  Stream<void> watchRevision() => events.stream;
}

class _TrashComicRepo implements ComicTrashRepository {
  _TrashComicRepo(this.items);

  final List<TrashedComic> items;

  @override
  Future<PagedResult<TrashedComic>> fetchTrashedPage(
    PageRequest request,
  ) async => PagedResult<TrashedComic>(
    items: items,
    totalCount: items.length,
    page: request.page,
    pageSize: request.pageSize,
  );

  @override
  Future<TrashedComicCounts> countTrashed() async => (
    total: items.length,
    local: items.where((TrashedComic i) => !i.isRemote).length,
    remote: items.where((TrashedComic i) => i.isRemote).length,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoopReaderSessionPort implements ComicTrashReaderSessionPort {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoCoverComicCover extends ComicCover {
  @override
  ComicCoverState build(String comicId) => const ComicCoverNoCover();
}

TrashedComic _trashed(String id, {bool remote = false}) {
  final DateTime t = DateTime.utc(2026, 10, 2, 8);
  return (
    comic: Comic(
      comicId: id,
      path: '/$id.cbz',
      resourceType: ResourceType.cbz,
      resourceSize: 1,
      createdAt: t,
      lastUpdatedAt: t,
      title: 'Title $id',
      pageCount: 1,
    ),
    deletedAt: t,
    libraryName: remote ? 'WebDAV' : 'Disk',
    isRemote: remote,
  );
}

Future<void> _pumpTrash(WidgetTester tester, List<TrashedComic> items) async {
  tester.view.physicalSize = const Size(1200, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final _FakeLibraryRevisionPort revision = _FakeLibraryRevisionPort();
  addTearDown(revision.events.close);
  await pumpLocalizedApp(
    tester,
    home: const Scaffold(body: TrashMd3ePage()),
    overrides: <Override>[
      libraryRevisionPortProvider.overrideWithValue(revision),
      comicTrashRepositoryProvider.overrideWithValue(_TrashComicRepo(items)),
      comicTrashReaderSessionPortProvider.overrideWithValue(
        _NoopReaderSessionPort(),
      ),
      for (final TrashedComic item in items)
        comicCoverProvider(item.comic.comicId)
            .overrideWith(_NoCoverComicCover.new),
    ],
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('empty trash shows explanatory empty state', (
    WidgetTester tester,
  ) async {
    await _pumpTrash(tester, const <TrashedComic>[]);

    expect(find.text('没有已删除的漫画'), findsOneWidget);
    expect(find.text('删除的漫画会先放在这里，可恢复或永久删除。'), findsOneWidget);
  });

  testWidgets('lists trashed comics with library and Local / Remote badge', (
    WidgetTester tester,
  ) async {
    await _pumpTrash(tester, <TrashedComic>[
      _trashed('a'),
      _trashed('b', remote: true),
    ]);

    expect(find.text('Title a'), findsOneWidget);
    expect(find.text('Title b'), findsOneWidget);
    expect(find.textContaining('Disk'), findsOneWidget);
    expect(find.textContaining('WebDAV'), findsOneWidget);
    expect(find.textContaining('本地'), findsOneWidget);
    expect(find.textContaining('远程'), findsOneWidget);
    expect(find.byIcon(Symbols.restore), findsOneWidget);
    expect(find.byIcon(Symbols.delete_forever), findsOneWidget);
  });

  testWidgets('tapping a row toggles selection and switches header actions', (
    WidgetTester tester,
  ) async {
    await _pumpTrash(tester, <TrashedComic>[_trashed('a'), _trashed('b')]);

    expect(find.byType(M3ECheckbox), findsNWidgets(2));

    await tester.tap(find.text('Title a'));
    await tester.pumpAndSettle();
    expect(find.text('已选 1 本'), findsOneWidget);
    expect(find.byType(M3ECheckbox), findsNWidgets(2));
    expect(find.byIcon(Symbols.restore), findsOneWidget);
    expect(find.byIcon(Symbols.delete_forever), findsOneWidget);
  });
}
