import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/app_settings/domain/app_setting.dart';
import 'package:hentai_library/features/app_settings/presentation/view_models/settings_notifier.dart';
import 'package:hentai_library/features/app_settings/public/providers/app_settings_providers.dart';
import 'package:hentai_library/features/comic/domain/comic.dart';
import 'package:hentai_library/features/comic/domain/repositories/comic_lookup_repository.dart';
import 'package:hentai_library/features/comic/domain/smart_facet_match.dart';
import 'package:hentai_library/features/comic/presentation/providers/comic_repository_providers.dart';
import 'package:hentai_library/features/comic/presentation/view_models/comic_metadata_smart_facet_providers.dart';
import 'package:hentai_library/features/comic/presentation/views/widgets/form/library_facet_multi_select_field.dart';
import 'package:hentai_library/features/comic_metadata/public/comic_metadata_entities.dart';
import 'package:hentai_library/features/comic_metadata/public/comic_metadata_form.dart';
import 'package:hentai_library/features/comic_metadata/public/providers.dart';
import 'package:hentai_library/features/library_admin/public.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/domain/reading/series_reading_context.dart';
import 'package:hentai_library/shared/presentation/providers/series_reading_context_providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;

import '../../../../support/pump_app.dart';

const ComicMetadataSmartFacetScope _scope = (
  comicId: 'current',
  title: 'book',
  resourcePath: '/library/Artist/book.cbz',
  seriesId: 'series',
);
const SeriesReadingContext _context = (
  seriesId: 'series',
  seriesName: 'series',
  orderedComicIds: ['current', 'missing', 'sibling'],
  currentIndex: 0,
);
const _catalog = <NamedFacetFormCandidate>[
  (name: 'Popular', attachmentCount: 10),
  (name: 'Artist', attachmentCount: 1),
];

class _Listing implements NamedFacetFormListing {
  _Listing(this.load);
  final Future<List<NamedFacetFormCandidate>> Function(NamedFacetFormKind) load;

  @override
  Future<List<NamedFacetFormCandidate>> listForMetadataForm(
    NamedFacetFormKind facet,
  ) => load(facet);
}

class _Lookup implements ComicLookupRepository {
  _Lookup(this.find);
  final Future<Comic?> Function(String) find;

  @override
  Future<Comic?> findById(String comicId) => find(comicId);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Settings extends SettingsNotifier {
  _Settings(this.load);
  final Future<AppSetting> Function() load;

  @override
  Future<AppSetting> build() => load();

  void enabled(bool value) =>
      state = AsyncData(AppSetting(smartFacetMatchEnabled: value));
}

class _Roots extends Notifier<LibrariesState> {
  @override
  LibrariesState build() => LibrariesState(libraries: [_library('/library')]);

  void root(String root) => state = LibrariesState(libraries: [_library(root)]);
}

final _rootsProvider = NotifierProvider<_Roots, LibrariesState>(_Roots.new);

LocalLibrary _library(String root) => (
  libraryId: 'library',
  kind: 'local',
  catalogKind: 'comic',
  rootPath: root,
  name: 'library',
  enabledResourceFormatCategories: ResourceFormatCategory.all,
  username: '',
  allowHttp: false,
  scanOnStartup: false,
  scanInterval: ScanInterval.disabled,
  pinned: false,
  sidebarOrder: 0,
);

Comic _sibling() => Comic.restore(
  comicId: 'sibling',
  path: '/library/Artist/sibling.cbz',
  resourceType: ResourceType.cbz,
  resourceSize: 0,
  createdAt: DateTime(2026),
  lastUpdatedAt: DateTime(2026),
  title: 'sibling',
  pageCount: 1,
  tags: [Tag(name: 'Artist')],
  parodies: ['Artist'],
  characters: ['Artist'],
);

FutureProvider<List<SmartFacetMatchCandidate>> _provider(
  NamedFacetFormKind kind, [
  ComicMetadataSmartFacetScope scope = _scope,
]) => switch (kind) {
  NamedFacetFormKind.author => authorsSmartForComicMetadataFormProvider(scope),
  NamedFacetFormKind.tag => tagsSmartForComicMetadataFormProvider(scope),
  NamedFacetFormKind.parody => parodiesSmartForComicMetadataFormProvider(scope),
  NamedFacetFormKind.character => charactersSmartForComicMetadataFormProvider(
    scope,
  ),
};

ProviderContainer _container(List<Override> overrides) {
  final container = ProviderContainer(overrides: overrides);
  addTearDown(container.dispose);
  return container;
}

List<Override> _base({bool enabled = true, bool includeListing = true}) => [
  if (includeListing)
    namedFacetFormListingProvider.overrideWithValue(
      _Listing((_) async => _catalog),
    ),
  appSettingsProvider.overrideWith(
    () => _Settings(() async => AppSetting(smartFacetMatchEnabled: enabled)),
  ),
];

void main() {
  test('catalog completes before settings and context completes before roots and members', () async {
    final calls = <String>[];
    final catalog = Completer<List<NamedFacetFormCandidate>>();
    final settings = Completer<AppSetting>();
    final context = Completer<SeriesReadingContext?>();
    final catalogRequested = Completer<void>();
    final settingsRequested = Completer<void>();
    final contextRequested = Completer<void>();
    final container = _container([
      namedFacetFormListingProvider.overrideWithValue(
        _Listing((kind) {
          calls.add('catalog:$kind');
          catalogRequested.complete();
          return catalog.future;
        }),
      ),
      appSettingsProvider.overrideWith(
        () => _Settings(() {
          calls.add('settings');
          settingsRequested.complete();
          return settings.future;
        }),
      ),
      librariesStateProvider.overrideWith((ref) {
        calls.add('roots');
        return AsyncData(LibrariesState(libraries: [_library('/library')]));
      }),
      findSeriesReadingContextQueryProvider.overrideWithValue((id) {
        calls.add('context:$id');
        contextRequested.complete();
        return context.future;
      }),
      comicLookupRepositoryProvider.overrideWithValue(
        _Lookup((id) async {
          calls.add('comic:$id');
          return id == 'missing' ? null : _sibling();
        }),
      ),
    ]);
    final provider = tagsSmartForComicMetadataFormProvider(_scope);
    container.listen(provider, (_, _) {});
    final result = container.read(provider.future);
    await catalogRequested.future;
    expect(calls, ['catalog:NamedFacetFormKind.tag']);
    catalog.complete(_catalog);
    await settingsRequested.future;
    expect(calls.last, 'settings');
    expect(calls, hasLength(2));
    settings.complete(AppSetting());
    await contextRequested.future;
    expect(calls, [
      'catalog:NamedFacetFormKind.tag',
      'settings',
      'context:current',
    ]);
    context.complete(_context);
    expect((await result).first.name, 'Artist');
    expect(calls, [
      'catalog:NamedFacetFormKind.tag',
      'settings',
      'context:current',
      'roots',
      'comic:missing',
      'comic:sibling',
    ]);
  });

  for (final kind in NamedFacetFormKind.values) {
    test('$kind binds its catalog and ranking inputs', () async {
      final listed = <NamedFacetFormKind>[];
      final lookedUp = <String>[];
      var contextCalls = 0;
      final container = _container([
        ..._base(includeListing: false),
        namedFacetFormListingProvider.overrideWithValue(
          _Listing((facet) async {
            listed.add(facet);
            return _catalog;
          }),
        ),
        librariesStateProvider.overrideWithValue(
          AsyncData(LibrariesState(libraries: [_library('/library')])),
        ),
        findSeriesReadingContextQueryProvider.overrideWithValue((_) async {
          contextCalls++;
          return _context;
        }),
        comicLookupRepositoryProvider.overrideWithValue(
          _Lookup((id) async {
            lookedUp.add(id);
            return id == 'missing' ? null : _sibling();
          }),
        ),
      ]);
      final provider = _provider(kind);
      container.listen(provider, (_, _) {});
      expect(await container.read(provider.future), [
        (name: 'Artist', attachmentCount: 1, smartMatched: true),
        (name: 'Popular', attachmentCount: 10, smartMatched: false),
      ]);
      expect(listed, [kind]);
      expect(contextCalls, kind == NamedFacetFormKind.author ? 0 : 1);
      expect(
        lookedUp,
        kind == NamedFacetFormKind.author ? isEmpty : ['missing', 'sibling'],
      );
      container.invalidate(findSeriesReadingContextQueryProvider);
      container.invalidate(comicLookupRepositoryProvider);
      await container.pump();
      expect(listed, [kind]);
      expect(contextCalls, kind == NamedFacetFormKind.author ? 0 : 1);
      expect(
        lookedUp,
        kind == NamedFacetFormKind.author ? isEmpty : ['missing', 'sibling'],
      );
    });
  }

  test(
    'one candidate query retains its lazy repository snapshot until refreshed',
    () async {
      final firstLookup = Completer<Comic?>();
      final firstLookupRequested = Completer<void>();
      final calls = <String>[];
      final oldRepository = _Lookup((id) {
        calls.add('old:$id');
        if (id == 'missing') {
          firstLookupRequested.complete();
          return firstLookup.future;
        }
        return Future.value(_sibling());
      });
      final newRepository = _Lookup((id) async {
        calls.add('new:$id');
        return id == 'missing'
            ? null
            : _sibling().copyWith(
                metadata: _sibling().metadata.copyWith(
                  tags: [Tag(name: 'Popular')],
                ),
              );
      });
      ComicLookupRepository repository = oldRepository;
      final container = _container([
        ..._base(),
        librariesStateProvider.overrideWithValue(
          AsyncData(LibrariesState(libraries: [_library('/library')])),
        ),
        findSeriesReadingContextQueryProvider.overrideWithValue(
          (_) async => _context,
        ),
        comicLookupRepositoryProvider.overrideWith((ref) => repository),
      ]);
      final provider = tagsSmartForComicMetadataFormProvider(_scope);
      container.listen(provider, (_, _) {});
      final first = container.read(provider.future);
      await firstLookupRequested.future;
      repository = newRepository;
      container.invalidate(comicLookupRepositoryProvider);
      await container.pump();
      firstLookup.complete(null);
      final originalResult = await first;
      final originalCalls = List<String>.of(calls);
      container.invalidate(provider);
      final refreshedResult = await container.read(provider.future);
      expect(originalCalls, ['old:missing', 'old:sibling']);
      expect(originalResult.first, (
        name: 'Artist',
        attachmentCount: 1,
        smartMatched: true,
      ));
      expect(calls, [
        'old:missing',
        'old:sibling',
        'new:missing',
        'new:sibling',
      ]);
      expect(refreshedResult.first, (
        name: 'Popular',
        attachmentCount: 10,
        smartMatched: true,
      ));
    },
  );

  test('settings changes recompute while read-only listing replacement does not subscribe', () async {
    var listings = 0;
    final container = _container([
      ..._base(includeListing: false),
      namedFacetFormListingProvider.overrideWith(
        (ref) => _Listing((_) async {
          listings++;
          return _catalog;
        }),
      ),
      librariesStateProvider.overrideWithValue(
        AsyncData(LibrariesState(libraries: [_library('/library')])),
      ),
    ]);
    final provider = authorsSmartForComicMetadataFormProvider(_scope);
    container.listen(provider, (_, _) {});
    expect((await container.read(provider.future)).first.smartMatched, isTrue);
    container.invalidate(namedFacetFormListingProvider);
    await container.pump();
    expect(listings, 1);
    final settings = container.read(appSettingsProvider.notifier) as _Settings;
    settings.enabled(false);
    await container.pump();
    final disabled = await container.read(provider.future);
    expect(disabled.map((c) => (c.name, c.smartMatched)), [
      ('Popular', false),
      ('Artist', false),
    ]);
    settings.enabled(true);
    await container.pump();
    expect((await container.read(provider.future)).first.smartMatched, isTrue);
    expect(listings, 3);
  });

  test(
    'author recomputes on library roots without querying siblings',
    () async {
      var listings = 0;
      final container = _container([
        ..._base(includeListing: false),
        namedFacetFormListingProvider.overrideWithValue(
          _Listing((_) async {
            listings++;
            return _catalog;
          }),
        ),
        librariesStateProvider.overrideWith(
          (ref) => AsyncData(ref.watch(_rootsProvider)),
        ),
      ]);
      final provider = authorsSmartForComicMetadataFormProvider(_scope);
      container.listen(provider, (_, _) {});
      expect(
        (await container.read(provider.future)).first.smartMatched,
        isTrue,
      );
      container.read(_rootsProvider.notifier).root('/library/Artist');
      await container.pump();
      expect(
        (await container.read(provider.future)).every((c) => !c.smartMatched),
        isTrue,
      );
      expect(listings, 2);
    },
  );

  for (final route in [
    'disabled',
    'no series',
    'root series',
    'missing context',
  ]) {
    test('$route does not require a Comic lookup binding', () async {
      final scope = (
        comicId: _scope.comicId,
        title: _scope.title,
        resourcePath: route == 'root series'
            ? '/library/book.cbz'
            : _scope.resourcePath,
        seriesId: route == 'no series' ? null : _scope.seriesId,
      );
      final container = _container([
        ..._base(enabled: route != 'disabled'),
        if (route == 'root series')
          librariesStateProvider.overrideWithValue(
            AsyncData(LibrariesState(libraries: [_library('/library')])),
          ),
        if (route == 'root series' || route == 'missing context')
          findSeriesReadingContextQueryProvider.overrideWithValue(
            (_) async => route == 'missing context' ? null : _context,
          ),
      ]);
      final provider = tagsSmartForComicMetadataFormProvider(scope);
      container.listen(provider, (_, _) {});
      final result = await container.read(provider.future);
      expect(result.map((c) => (c.name, c.smartMatched)), [
        ('Popular', false),
        ('Artist', false),
      ]);
    });
  }

  for (final source in ['catalog', 'settings']) {
    test(
      '$source failure propagates without reading downstream providers',
      () async {
        final failure = StateError('$source unavailable');
        final container = _container([
          namedFacetFormListingProvider.overrideWithValue(
            _Listing((_) async {
              if (source == 'catalog') throw failure;
              return _catalog;
            }),
          ),
          if (source == 'settings')
            appSettingsProvider.overrideWith(
              () => _Settings(() async => throw failure),
            ),
        ]);
        final provider = tagsSmartForComicMetadataFormProvider(_scope);
        container.listen(provider, (_, _) {});
        await expectLater(
          container.read(provider.future),
          throwsA(same(failure)),
        );
      },
    );
  }

  testWidgets('public form still accepts the existing family override', (
    tester,
  ) async {
    final selected = <String>[];
    await pumpApp(
      tester,
      overrides: [
        authorsSmartForComicMetadataFormProvider(_scope).overrideWith(
          (_) async => <SmartFacetMatchCandidate>[
            (name: 'Artist', attachmentCount: 1, smartMatched: true),
          ],
        ),
      ],
      home: Center(
        child: SizedBox(
          width: 360,
          child: LibraryFacetMultiSelectField(
            kind: NamedFacetFormKind.author,
            label: '作者',
            selectedNames: const [],
            onAdd: selected.add,
            onRemove: (_) {},
            scope: _scope,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Artist').last);
    await tester.pumpAndSettle();
    expect(selected, ['Artist']);
  });
}
