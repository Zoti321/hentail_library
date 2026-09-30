import 'package:hentai_library/domain/library/smart_facet_match.dart';
import 'package:hentai_library/domain/models/named_facet_form_candidate.dart';
import 'package:test/test.dart';

void main() {
  group('applySmartFacetMatch', () {
    final List<NamedFacetFormCandidate> catalog = <NamedFacetFormCandidate>[
      namedFacetFormCandidate(name: 'zeta', attachmentCount: 10),
      namedFacetFormCandidate(name: 'alpha', attachmentCount: 5),
      namedFacetFormCandidate(name: 'beta', attachmentCount: 1),
    ];

    test(
      'when disabled, keeps attachment count order and marks none matched',
      () {
        final List<SmartFacetMatchCandidate> ranked = applySmartFacetMatch(
          candidates: catalog,
          matchedSourceCounts: <String, int>{'beta': 1},
          enabled: false,
        );

        expect(
          ranked.map((SmartFacetMatchCandidate c) => (c.name, c.smartMatched)),
          <(String, bool)>[('zeta', false), ('alpha', false), ('beta', false)],
        );
      },
    );

    test('when enabled, matched names rank before attachment count', () {
      final List<SmartFacetMatchCandidate> ranked = applySmartFacetMatch(
        candidates: catalog,
        matchedSourceCounts: <String, int>{'beta': 1},
        enabled: true,
      );

      expect(
        ranked.map((SmartFacetMatchCandidate c) => (c.name, c.smartMatched)),
        <(String, bool)>[('beta', true), ('zeta', false), ('alpha', false)],
      );
    });

    test('within matched group, sorts by attachment count then name', () {
      final List<NamedFacetFormCandidate> candidates =
          <NamedFacetFormCandidate>[
            namedFacetFormCandidate(name: 'm-low', attachmentCount: 1),
            namedFacetFormCandidate(name: 'm-high', attachmentCount: 9),
            namedFacetFormCandidate(name: 'm-mid-b', attachmentCount: 3),
            namedFacetFormCandidate(name: 'm-mid-a', attachmentCount: 3),
            namedFacetFormCandidate(name: 'other', attachmentCount: 100),
          ];

      final List<SmartFacetMatchCandidate> ranked = applySmartFacetMatch(
        candidates: candidates,
        matchedSourceCounts: <String, int>{
          'm-low': 1,
          'm-high': 1,
          'm-mid-b': 1,
          'm-mid-a': 1,
        },
        enabled: true,
      );

      expect(
        ranked.map((SmartFacetMatchCandidate c) => c.name).toList(),
        <String>['m-high', 'm-mid-a', 'm-mid-b', 'm-low', 'other'],
      );
    });

    test('within matched group, sorts by source count before attachment', () {
      final List<NamedFacetFormCandidate> candidates =
          <NamedFacetFormCandidate>[
            namedFacetFormCandidate(name: 'one-source', attachmentCount: 100),
            namedFacetFormCandidate(name: 'three-source', attachmentCount: 1),
            namedFacetFormCandidate(name: 'two-source', attachmentCount: 50),
            namedFacetFormCandidate(name: 'other', attachmentCount: 200),
          ];

      final List<SmartFacetMatchCandidate> ranked = applySmartFacetMatch(
        candidates: candidates,
        matchedSourceCounts: <String, int>{
          'one-source': 1,
          'two-source': 2,
          'three-source': 3,
        },
        enabled: true,
      );

      expect(
        ranked.map((SmartFacetMatchCandidate c) => c.name).toList(),
        <String>['three-source', 'two-source', 'one-source', 'other'],
      );
    });

    test('dictionary-only: matched names absent from catalog are ignored', () {
      final List<SmartFacetMatchCandidate> ranked = applySmartFacetMatch(
        candidates: catalog,
        matchedSourceCounts: <String, int>{'ghost': 2, 'beta': 1},
        enabled: true,
      );

      expect(
        ranked.any((SmartFacetMatchCandidate c) => c.name == 'ghost'),
        isFalse,
      );
      expect(ranked.first.name, 'beta');
    });
  });

  group('authorSmartMatchNames', () {
    final List<NamedFacetFormCandidate> authors = <NamedFacetFormCandidate>[
      namedFacetFormCandidate(name: 'Alice', attachmentCount: 2),
      namedFacetFormCandidate(name: 'Bob', attachmentCount: 1),
      namedFacetFormCandidate(name: 'Carol', attachmentCount: 1),
      namedFacetFormCandidate(name: 'エス書店 (さんい)', attachmentCount: 5),
      namedFacetFormCandidate(name: 'エス書店', attachmentCount: 3),
      namedFacetFormCandidate(name: 'あ', attachmentCount: 1),
      namedFacetFormCandidate(name: 'X', attachmentCount: 1),
      namedFacetFormCandidate(name: '画', attachmentCount: 1),
    ];

    test('matches author substring in title case-insensitively', () {
      expect(
        authorSmartMatchNames(
          dictionary: authors,
          title: 'Works by ALICE vol.1',
          filenameStem: 'chapter01',
          parentDirectorySegments: const <String>[],
        ),
        <String, int>{'Alice': 1},
      );
    });

    test('matches author substring in filename stem independently', () {
      expect(
        authorSmartMatchNames(
          dictionary: authors,
          title: 'Untitled',
          filenameStem: 'Works by Bob vol.1',
          parentDirectorySegments: const <String>[],
        ),
        <String, int>{'Bob': 1},
      );
    });

    test('matches author substring in parent directory segments', () {
      expect(
        authorSmartMatchNames(
          dictionary: authors,
          title: 'Untitled',
          filenameStem: 'chapter01',
          parentDirectorySegments: const <String>['Bob', 'series'],
        ),
        <String, int>{'Bob': 1},
      );
    });

    test('counts multiple independent sources for the same author', () {
      expect(
        authorSmartMatchNames(
          dictionary: authors,
          title: 'Works by Alice',
          filenameStem: 'Alice special',
          parentDirectorySegments: const <String>['Alice'],
        ),
        <String, int>{'Alice': 3},
      );
    });

    test('dedupes title and filename when normalized content is identical', () {
      expect(
        authorSmartMatchNames(
          dictionary: authors,
          title: 'Alice Collection',
          filenameStem: 'Alice Collection',
          parentDirectorySegments: const <String>[],
        ),
        <String, int>{'Alice': 1},
      );
    });

    test('matches doujin filename stem as whole dictionary substring', () {
      expect(
        authorSmartMatchNames(
          dictionary: authors,
          title: 'THE YOUTH',
          filenameStem: '(COMIC1☆9) [エス書店 (さんい)] THE YOUTH (アイドルマスター)',
          parentDirectorySegments: const <String>[],
        ),
        <String, int>{'エス書店 (さんい)': 1, 'エス書店': 1},
      );
    });

    test('skips single latin author names', () {
      expect(
        authorSmartMatchNames(
          dictionary: authors,
          title: 'X marks',
          filenameStem: 'x',
          parentDirectorySegments: const <String>['x'],
        ),
        isEmpty,
      );
    });

    test('allows single CJK author names', () {
      expect(
        authorSmartMatchNames(
          dictionary: authors,
          title: '画集',
          filenameStem: 'file',
          parentDirectorySegments: const <String>[],
        ),
        <String, int>{'画': 1},
      );
      expect(
        authorSmartMatchNames(
          dictionary: authors,
          title: 'あいう',
          filenameStem: 'a',
          parentDirectorySegments: const <String>[],
        ),
        <String, int>{'あ': 1},
      );
    });

    test('does not count filename stem as a parent directory segment', () {
      expect(
        authorSmartMatchNames(
          dictionary: authors,
          title: 'Untitled',
          filenameStem: 'Carol edition',
          parentDirectorySegments: const <String>['Carol'],
        ),
        <String, int>{'Carol': 2},
      );
    });
  });

  group('resolveAuthorSmartMatchPathSources', () {
    test('uses relative path when resource is under library root', () {
      final AuthorSmartMatchPathSources sources =
          resolveAuthorSmartMatchPathSources(
            resourcePath: r'E:\libs\mine\Bob\chapter01.cbz',
            relativeUnderLibraryRoot: r'Bob\chapter01.cbz',
            libraryRootKnown: true,
          );

      expect(sources.filenameStem, 'chapter01');
      expect(sources.parentDirectorySegments, <String>['Bob']);
    });

    test('uses full resource path when library root is unknown', () {
      final AuthorSmartMatchPathSources sources =
          resolveAuthorSmartMatchPathSources(
            resourcePath: r'E:\drop\Carol\chapter01.cbz',
            relativeUnderLibraryRoot: null,
            libraryRootKnown: false,
          );

      expect(sources.filenameStem, 'chapter01');
      expect(sources.parentDirectorySegments, <String>['E:', 'drop', 'Carol']);
    });

    test('uses basename only when resource is outside known library root', () {
      final AuthorSmartMatchPathSources sources =
          resolveAuthorSmartMatchPathSources(
            resourcePath: r'D:\outside\Carol edition.cbz',
            relativeUnderLibraryRoot: null,
            libraryRootKnown: true,
          );

      expect(sources.filenameStem, 'Carol edition');
      expect(sources.parentDirectorySegments, isEmpty);
    });
  });

  group('authorSmartMatchPathSources', () {
    test('splits relative path into stem and parent segments', () {
      final AuthorSmartMatchPathSources sources = authorSmartMatchPathSources(
        relativeResourcePath: r'Bob\series\chapter01.cbz',
      );

      expect(sources.filenameStem, 'chapter01');
      expect(sources.parentDirectorySegments, <String>['Bob', 'series']);
    });

    test('returns empty parent segments for basename-only path', () {
      final AuthorSmartMatchPathSources sources = authorSmartMatchPathSources(
        relativeResourcePath: 'chapter01.cbz',
      );

      expect(sources.filenameStem, 'chapter01');
      expect(sources.parentDirectorySegments, isEmpty);
    });
  });

  group('siblingSmartMatchNames', () {
    final List<NamedFacetFormCandidate> tags = <NamedFacetFormCandidate>[
      namedFacetFormCandidate(name: 'yuri', attachmentCount: 3),
      namedFacetFormCandidate(name: 'original', attachmentCount: 1),
      namedFacetFormCandidate(name: 'unused', attachmentCount: 0),
    ];

    test('intersects sibling attachments with dictionary', () {
      expect(
        siblingSmartMatchNames(
          dictionary: tags,
          siblingAttachedNames: <String>{'yuri', 'not-in-dict'},
          isLibraryRootSeries: false,
        ),
        <String>{'yuri'},
      );
    });

    test('returns empty for library root series', () {
      expect(
        siblingSmartMatchNames(
          dictionary: tags,
          siblingAttachedNames: <String>{'yuri'},
          isLibraryRootSeries: true,
        ),
        isEmpty,
      );
    });
  });

  group('relativeResourcePathUnderRoot', () {
    test('strips library root prefix with normalized separators', () {
      expect(
        relativeResourcePathUnderRoot(
          resourcePath: r'E:\libs\mine\series\a.cbz',
          libraryRoot: r'E:\libs\mine',
        ),
        r'series\a.cbz',
      );
    });

    test('returns null when path is outside root', () {
      expect(
        relativeResourcePathUnderRoot(
          resourcePath: r'D:\other\a.cbz',
          libraryRoot: r'E:\libs\mine',
        ),
        isNull,
      );
    });
  });

  group('isLibraryRootSeriesFolder', () {
    test('detects equal paths case-insensitively on Windows', () {
      expect(
        isLibraryRootSeriesFolder(
          seriesFolderPath: r'E:\Libs\Mine',
          libraryRoot: r'e:\libs\mine',
        ),
        isTrue,
      );
    });

    test('returns false for nested folder series', () {
      expect(
        isLibraryRootSeriesFolder(
          seriesFolderPath: r'E:\libs\mine\story',
          libraryRoot: r'E:\libs\mine',
        ),
        isFalse,
      );
    });
  });
}
