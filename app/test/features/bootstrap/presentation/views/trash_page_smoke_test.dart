import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/shared/domain/models/read_models/trashed_comic.dart';
import 'package:hentai_library/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/domain/ports/library_revision_port.dart';
import 'package:hentai_library/domain/repositories/comic_repository.dart';
import 'package:hentai_library/ui/core/dto/comic_cover_state.dart';
import 'package:hentai_library/features/bootstrap/di/ports.dart';
import 'package:hentai_library/features/bootstrap/di/repos.dart';
import 'package:hentai_library/features/comic_trash/presentation/views/trash_page/trash_page.dart';
import 'package:hentai_library/ui/providers/comic_cover_providers.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:riverpod/misc.dart' show Override;

import '../../../../support/pump_localized_app.dart';

class _FakeLibraryRevisionPort implements LibraryRevisionPort {
  final StreamController<void> events = StreamController<void>.broadcast();

  @override
  Stream<void> watchRevision() => events.stream;
}

class _TrashComicRepo implements ComicRepository {
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
    home: const Scaffold(body: TrashPage()),
    overrides: <Override>[
      libraryRevisionPortProvider.overrideWithValue(revision),
      comicRepoProvider.overrideWithValue(_TrashComicRepo(items)),
      for (final TrashedComic item in items)
        comicCoverProvider(
          item.comic.comicId,
        ).overrideWith(_NoCoverComicCover.new),
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
    expect(find.text('Disk'), findsOneWidget);
    expect(find.text('WebDAV'), findsOneWidget);
    expect(find.text('本地'), findsOneWidget);
    expect(find.text('远程'), findsOneWidget);
    expect(find.text('全部恢复'), findsOneWidget);
    expect(find.text('全部删除'), findsOneWidget);
  });

  testWidgets('starts in selection mode and uses cover corner badges', (
    WidgetTester tester,
  ) async {
    await _pumpTrash(tester, <TrashedComic>[_trashed('a'), _trashed('b')]);

    expect(find.byType(Checkbox), findsNothing);
    expect(find.byIcon(LucideIcons.check), findsNothing);

    await tester.tap(find.text('Title a'));
    await tester.pumpAndSettle();
    expect(find.text('已选 1 本'), findsOneWidget);
    expect(find.byIcon(LucideIcons.check), findsOneWidget);
    expect(find.text('恢复选中'), findsOneWidget);
    expect(find.text('删除选中'), findsOneWidget);
  });
}
