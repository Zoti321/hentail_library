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
          matchedNames: <String>{'beta'},
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
        matchedNames: <String>{'beta'},
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
        matchedNames: <String>{'m-low', 'm-high', 'm-mid-b', 'm-mid-a'},
        enabled: true,
      );

      expect(
        ranked.map((SmartFacetMatchCandidate c) => c.name).toList(),
        <String>['m-high', 'm-mid-a', 'm-mid-b', 'm-low', 'other'],
      );
    });

    test('dictionary-only: matched names absent from catalog are ignored', () {
      final List<SmartFacetMatchCandidate> ranked = applySmartFacetMatch(
        candidates: catalog,
        matchedNames: <String>{'ghost', 'beta'},
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
      namedFacetFormCandidate(name: 'あ', attachmentCount: 1),
      namedFacetFormCandidate(name: 'X', attachmentCount: 1),
      namedFacetFormCandidate(name: '画', attachmentCount: 1),
    ];

    test('matches author substring in title case-insensitively', () {
      expect(
        authorSmartMatchNames(
          dictionary: authors,
          title: 'Works by ALICE vol.1',
          relativeResourcePath: 'series/file.cbz',
        ),
        <String>{'Alice'},
      );
    });

    test('matches author substring in relative path segments', () {
      expect(
        authorSmartMatchNames(
          dictionary: authors,
          title: 'Untitled',
          relativeResourcePath: 'Bob/chapter01.cbz',
        ),
        <String>{'Bob'},
      );
    });

    test('skips single latin author names', () {
      expect(
        authorSmartMatchNames(
          dictionary: authors,
          title: 'X marks',
          relativeResourcePath: 'x/file.cbz',
        ),
        isEmpty,
      );
    });

    test('allows single CJK author names', () {
      expect(
        authorSmartMatchNames(
          dictionary: authors,
          title: '画集',
          relativeResourcePath: 'folder/file.cbz',
        ),
        <String>{'画'},
      );
      expect(
        authorSmartMatchNames(
          dictionary: authors,
          title: 'あいう',
          relativeResourcePath: 'a.cbz',
        ),
        <String>{'あ'},
      );
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
