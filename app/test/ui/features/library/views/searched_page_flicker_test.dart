import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/domain/library/format_group.dart';
import 'package:hentai_library/domain/library/scan_interval.dart';
import 'package:hentai_library/domain/models/entity/comic/author.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/domain/ports/library_revision_port.dart';
import 'package:hentai_library/domain/repositories/author_repository.dart';
import 'package:hentai_library/domain/repositories/comic_repository.dart';
import 'package:hentai_library/domain/repositories/named_facet_dictionary_repository.dart';
import 'package:hentai_library/domain/repositories/tag_repository.dart';
import 'package:hentai_library/ui/core/dto/comic_cover_state.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/element/card/comic_card.dart';
import 'package:hentai_library/ui/core/widgets/element/chip/meta_chip.dart';
import 'package:hentai_library/ui/features/library/views/searched_page.dart';
import 'package:hentai_library/ui/features/shell/di/ports.dart';
import 'package:hentai_library/ui/features/shell/di/repos.dart';
import 'package:hentai_library/ui/features/shell/state/current_library_notifier.dart';
import 'package:hentai_library/ui/features/shell/state/library_revision_notifier.dart';
import 'package:hentai_library/ui/providers/comic_cover_providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;

Comic _comic(String id) {
  final DateTime now = DateTime.utc(2026, 1, 1);
  return Comic(
    comicId: id,
    path: '/$id',
    resourceType: ResourceType.zip,
    resourceSize: 1,
    createdAt: now,
    lastUpdatedAt: now,
    title: id,
    pageCount: 1,
  );
}

class _FakeLibraryRevisionPort implements LibraryRevisionPort {
  _FakeLibraryRevisionPort(this._events);

  final StreamController<void> _events;

  @override
  Stream<void> watchRevision() => _events.stream;
}

class _FakeCurrentLibraryNotifier extends CurrentLibraryNotifier {
  @override
  Future<CurrentLibraryState> build() async {
    const LocalLibrary library = (
      libraryId: 'lib-a',
      kind: 'local',
      rootPath: '/a',
      name: 'A',
      enabledFormatGroups: <FormatGroup>[],
      username: '',
      allowHttp: false,
      scanOnStartup: false,
      scanInterval: ScanInterval.disabled,
      pinned: true,
      sidebarOrder: 0,
    );
    return const CurrentLibraryState(
      libraries: <LocalLibrary>[library],
      currentId: 'lib-a',
    );
  }
}

class _EmptyFacetRepo implements NamedFacetDictionaryRepository {
  @override
  Future<List<String>> listAll() async => const <String>[];

  @override
  Future<List<String>> listDistinct({String? libraryId}) async =>
      const <String>[];
}

class _EmptyTagRepo implements TagRepository {
  @override
  Future<List<Tag>> listAll() async => const <Tag>[];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _EmptyAuthorRepo implements AuthorRepository {
  @override
  Future<List<Author>> listAll() async => const <Author>[];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingComicRepo implements ComicRepository {
  _RecordingComicRepo(this.items);

  final List<Comic> items;
  int keywordSearchCalls = 0;
  final Completer<void> _gate = Completer<void>();
  bool holdNextSearch = false;

  void releaseGate() {
    if (!_gate.isCompleted) {
      _gate.complete();
    }
  }

  @override
  Future<PagedResult<Comic>> searchByKeywordPage({
    required String keyword,
    required PageRequest request,
  }) async {
    keywordSearchCalls++;
    if (holdNextSearch) {
      holdNextSearch = false;
      await _gate.future;
    }
    return PagedResult<Comic>(
      items: items,
      totalCount: items.length,
      page: request.page,
      pageSize: request.pageSize,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoCoverComicCover extends ComicCover {
  @override
  ComicCoverState build(String comicId) => const ComicCoverNoCover();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'revision bump while search results visible must not flash loading/empty',
    (WidgetTester tester) async {
      final StreamController<void> revisionEvents =
          StreamController<void>.broadcast();
      addTearDown(revisionEvents.close);

      final _RecordingComicRepo comics = _RecordingComicRepo(<Comic>[
        _comic('c1'),
        _comic('c2'),
      ]);

      tester.view.physicalSize = const Size(900, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          libraryRevisionPortProvider.overrideWithValue(
            _FakeLibraryRevisionPort(revisionEvents),
          ),
          currentLibraryProvider.overrideWith(_FakeCurrentLibraryNotifier.new),
          tagRepoProvider.overrideWithValue(_EmptyTagRepo()),
          authorRepoProvider.overrideWithValue(_EmptyAuthorRepo()),
          parodyRepoProvider.overrideWithValue(_EmptyFacetRepo()),
          characterRepoProvider.overrideWithValue(_EmptyFacetRepo()),
          comicRepoProvider.overrideWithValue(comics),
          comicCoverProvider('c1').overrideWith(_NoCoverComicCover.new),
          comicCoverProvider('c2').overrideWith(_NoCoverComicCover.new),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: buildAppTheme(Brightness.light),
            home: const Scaffold(body: SearchedPage(query: 'foo')),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ComicCard), findsNWidgets(2));
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.widget<MetaChip>(find.byType(MetaChip)).label, '2');
      final int searchesAfterFirstLoad = comics.keywordSearchCalls;
      expect(searchesAfterFirstLoad, greaterThan(0));

      // Simulate thumbnail / metadata writes bumping SQLite data_version.
      comics.holdNextSearch = true;
      container.read(libraryRevisionProvider.notifier).notifyExternalChange();

      // Rebuilds scheduled; search is gated so we can observe the mid-refresh UI.
      await tester.pump();
      await tester.pump();

      final bool flashedLoading =
          find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
      final bool lostCards = find.byType(ComicCard).evaluate().length < 2;
      final bool countChurned =
          tester.widget<MetaChip>(find.byType(MetaChip)).label != '2';
      final bool refetched = comics.keywordSearchCalls > searchesAfterFirstLoad;

      comics.releaseGate();
      await tester.pumpAndSettle();

      expect(
        flashedLoading || lostCards || countChurned || refetched,
        isFalse,
        reason:
            'revision bump flashed or refetched search UI '
            '(loading=$flashedLoading, lostCards=$lostCards, '
            'countChurned=$countChurned, refetched=$refetched, '
            'searches=${comics.keywordSearchCalls})',
      );
    },
  );
}
