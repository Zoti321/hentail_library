import 'dart:async';

import 'package:hentai_library/features/comic/application/load_comic_smart_facet_candidates_use_case.dart';
import 'package:hentai_library/features/comic/domain/comic.dart';
import 'package:hentai_library/features/comic_metadata/public/comic_metadata_entities.dart';
import 'package:hentai_library/features/comic_metadata/public/comic_metadata_form.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/domain/reading/series_reading_context.dart';
import 'package:test/test.dart';

const ComicMetadataSmartFacetScope _scope = (
  comicId: 'current',
  title: 'Untitled',
  resourcePath: '/library/story/current.cbz',
  seriesId: 'series',
);

void main() {
  group('LoadComicSmartFacetCandidatesUseCase', () {
    for (final kind in NamedFacetFormKind.values) {
      test(
        'disabled $kind preserves catalog order without context reads',
        () async {
          final fixture = _Fixture()..enabled = false;
          final load = fixture.load;
          expect(fixture.calls, isEmpty);

          final result = await load(scope: _scope, kind: kind);

          expect(result, [
            (name: 'alpha', attachmentCount: 1, smartMatched: false),
            (name: 'beta', attachmentCount: 10, smartMatched: false),
          ]);
          expect(fixture.calls, ['list:${kind.name}', 'enabled']);
        },
      );
    }

    test(
      'author ranking uses independent sources under the closest root',
      () async {
        final fixture = _Fixture()
          ..catalog = [
            (name: 'Bob', attachmentCount: 1000),
            (name: 'Excluded', attachmentCount: 200),
            (name: 'Unmatched', attachmentCount: 300),
            (name: 'Alice', attachmentCount: 1),
          ]
          ..roots = [
            '/outside',
            '/outside/Excluded/Library',
            '/outside/Exclude',
          ];

        final result = await fixture.load(
          scope: (
            comicId: 'current',
            title: 'Alice collection with Bob',
            resourcePath: '/outside/Excluded/Library/Alice/Alice chapter.cbz',
            seriesId: 'series',
          ),
          kind: NamedFacetFormKind.author,
        );

        expect(result, [
          (name: 'Alice', attachmentCount: 1, smartMatched: true),
          (name: 'Bob', attachmentCount: 1000, smartMatched: true),
          (name: 'Excluded', attachmentCount: 200, smartMatched: false),
          (name: 'Unmatched', attachmentCount: 300, smartMatched: false),
        ]);
        expect(fixture.calls, ['list:author', 'enabled', 'roots']);
      },
    );

    for (final kind in [
      NamedFacetFormKind.tag,
      NamedFacetFormKind.parody,
      NamedFacetFormKind.character,
    ]) {
      test(
        '$kind aggregates siblings sequentially without repeated weighting',
        () async {
          final prefix = kind.name;
          final fixture = _Fixture()
            ..catalog = [
              (name: '$prefix-other', attachmentCount: 100),
              (name: '$prefix-current-only', attachmentCount: 99),
              (name: '$prefix-beta', attachmentCount: 10),
              (name: '$prefix-alpha', attachmentCount: 1),
            ]
            ..context = _context([
              'current',
              'sibling-b',
              'missing',
              'sibling-a',
              'current',
            ])
            ..comics = {
              'current': _comic('current', 'current-only'),
              'sibling-b': _comic(
                'sibling-b',
                'alpha',
                extra: ['alpha', 'outside'],
              ),
              'sibling-a': _comic('sibling-a', 'alpha', extra: ['beta']),
            };
          final firstSibling = Completer<Comic?>();
          fixture.pending['sibling-b'] = firstSibling;

          final pending = fixture.load(scope: _scope, kind: kind);
          await Future<void>.delayed(Duration.zero);
          expect(fixture.calls, [
            'list:$prefix',
            'enabled',
            'context:current',
            'roots',
            'comic:sibling-b',
          ]);
          firstSibling.complete(fixture.comics['sibling-b']);
          final result = await pending;

          expect(result, [
            (name: '$prefix-beta', attachmentCount: 10, smartMatched: true),
            (name: '$prefix-alpha', attachmentCount: 1, smartMatched: true),
            (name: '$prefix-other', attachmentCount: 100, smartMatched: false),
            (
              name: '$prefix-current-only',
              attachmentCount: 99,
              smartMatched: false,
            ),
          ]);
          expect(fixture.calls, [
            'list:$prefix',
            'enabled',
            'context:current',
            'roots',
            'comic:sibling-b',
            'comic:missing',
            'comic:sibling-a',
          ]);
        },
      );
    }

    for (final scenario in [
      (
        name: 'no series',
        seriesId: null,
        context: _context(),
        root: '/library',
        path: _scope.resourcePath,
        reads: <String>[],
      ),
      (
        name: 'empty series',
        seriesId: '',
        context: _context(),
        root: '/library',
        path: _scope.resourcePath,
        reads: <String>[],
      ),
      (
        name: 'missing context',
        seriesId: 'series',
        context: null,
        root: '/library',
        path: _scope.resourcePath,
        reads: ['context:current'],
      ),
      (
        name: 'library root series',
        seriesId: 'series',
        context: _context(),
        root: '/library/story',
        path: _scope.resourcePath,
        reads: ['context:current', 'roots'],
      ),
    ]) {
      test('${scenario.name} does not read sibling comics', () async {
        final fixture = _Fixture()
          ..context = scenario.context
          ..roots = [scenario.root];

        final result = await fixture.load(
          scope: (
            comicId: 'current',
            title: 'Untitled',
            resourcePath: scenario.path,
            seriesId: scenario.seriesId,
          ),
          kind: NamedFacetFormKind.tag,
        );

        expect(result, [
          (name: 'alpha', attachmentCount: 1, smartMatched: false),
          (name: 'beta', attachmentCount: 10, smartMatched: false),
        ]);
        expect(fixture.calls, ['list:tag', 'enabled', ...scenario.reads]);
      });
    }

    for (final scenario in [
      (stage: 'list:tag', calls: ['list:tag']),
      (stage: 'enabled', calls: ['list:tag', 'enabled']),
      (
        stage: 'context:current',
        calls: ['list:tag', 'enabled', 'context:current'],
      ),
      (
        stage: 'roots',
        calls: ['list:tag', 'enabled', 'context:current', 'roots'],
      ),
      (
        stage: 'comic:sibling-b',
        calls: [
          'list:tag',
          'enabled',
          'context:current',
          'roots',
          'comic:sibling-b',
        ],
      ),
      (
        stage: 'comic:sibling-a',
        calls: [
          'list:tag',
          'enabled',
          'context:current',
          'roots',
          'comic:sibling-b',
          'comic:sibling-a',
        ],
      ),
    ]) {
      test(
        '${scenario.stage} failure propagates even with an empty catalog',
        () async {
          final failure = StateError(scenario.stage);
          final fixture = _Fixture()
            ..catalog = []
            ..failAt = scenario.stage
            ..failure = failure;

          await expectLater(
            fixture.load(scope: _scope, kind: NamedFacetFormKind.tag),
            throwsA(same(failure)),
          );

          expect(fixture.calls, scenario.calls);
        },
      );
    }

    test(
      'each call reads a fresh catalog, settings, context and comics',
      () async {
        final fixture = _Fixture()
          ..catalog = [(name: 'tag-alpha', attachmentCount: 1)]
          ..context = _context(['current', 'first'])
          ..comics = {'first': _comic('first', 'alpha')};
        final load = fixture.load;

        final first = await load(scope: _scope, kind: NamedFacetFormKind.tag);
        fixture
          ..catalog = [(name: 'tag-beta', attachmentCount: 2)]
          ..context = _context(['current', 'second'])
          ..comics = {'second': _comic('second', 'beta')};
        final second = await load(scope: _scope, kind: NamedFacetFormKind.tag);
        fixture.enabled = false;
        final disabled = await load(
          scope: _scope,
          kind: NamedFacetFormKind.tag,
        );

        expect(first, [
          (name: 'tag-alpha', attachmentCount: 1, smartMatched: true),
        ]);
        expect(second, [
          (name: 'tag-beta', attachmentCount: 2, smartMatched: true),
        ]);
        expect(disabled, [
          (name: 'tag-beta', attachmentCount: 2, smartMatched: false),
        ]);
        expect(fixture.calls, [
          'list:tag',
          'enabled',
          'context:current',
          'roots',
          'comic:first',
          'list:tag',
          'enabled',
          'context:current',
          'roots',
          'comic:second',
          'list:tag',
          'enabled',
        ]);
      },
    );
  });
}

SeriesReadingContext _context([
  List<String> ids = const ['current', 'sibling-b', 'sibling-a'],
]) => (
  seriesId: 'series',
  seriesName: 'Story',
  orderedComicIds: ids,
  currentIndex: 0,
);

Comic _comic(String id, String name, {List<String> extra = const []}) {
  final names = [name, ...extra];
  return Comic.restore(
    comicId: id,
    path: '/library/story/$id.cbz',
    resourceType: ResourceType.zip,
    resourceSize: 1,
    createdAt: DateTime.utc(2026),
    lastUpdatedAt: DateTime.utc(2026),
    title: id,
    pageCount: 1,
    tags: [for (final value in names) Tag(name: 'tag-$value')],
    parodies: [for (final value in names) 'parody-$value'],
    characters: [for (final value in names) 'character-$value'],
  );
}

class _Fixture implements NamedFacetFormListing {
  List<NamedFacetFormCandidate> catalog = [
    (name: 'alpha', attachmentCount: 1),
    (name: 'beta', attachmentCount: 10),
  ];
  bool enabled = true;
  Iterable<String> roots = ['/library'];
  SeriesReadingContext? context = _context();
  Map<String, Comic> comics = {};
  final pending = <String, Completer<Comic?>>{};
  final calls = <String>[];
  String? failAt;
  Object failure = StateError('dependency failed');

  late final load = LoadComicSmartFacetCandidatesUseCase(
    listing: this,
    isEnabled: () async {
      _record('enabled');
      return enabled;
    },
    libraryRoots: () {
      _record('roots');
      return roots;
    },
    findSeriesReadingContext: (id) async {
      _record('context:$id');
      return context;
    },
    findComicById: (id) async {
      _record('comic:$id');
      if (pending[id] case final gate?) return await gate.future;
      return comics[id];
    },
  );

  void _record(String call) {
    calls.add(call);
    if (call == failAt) throw failure;
  }

  @override
  Future<List<NamedFacetFormCandidate>> listForMetadataForm(
    NamedFacetFormKind facet,
  ) async {
    _record('list:${facet.name}');
    return catalog;
  }
}
