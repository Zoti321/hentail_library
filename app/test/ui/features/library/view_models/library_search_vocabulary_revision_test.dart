import 'dart:async';

import 'package:hentai_library/domain/library/format_group.dart';
import 'package:hentai_library/domain/library/scan_interval.dart';
import 'package:hentai_library/domain/models/entity/comic/author.dart';
import 'package:hentai_library/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/domain/ports/library_revision_port.dart';
import 'package:hentai_library/domain/repositories/author_repository.dart';
import 'package:hentai_library/domain/repositories/named_facet_dictionary_repository.dart';
import 'package:hentai_library/domain/repositories/tag_repository.dart';
import 'package:hentai_library/ui/features/library/view_models/library_search_page_providers.dart';
import 'package:hentai_library/ui/features/library/view_models/library_search_query_parser.dart';
import 'package:hentai_library/ui/features/shell/di/ports.dart';
import 'package:hentai_library/ui/features/shell/di/repos.dart';
import 'package:hentai_library/ui/features/shell/state/current_library_notifier.dart';
import 'package:hentai_library/ui/features/shell/state/library_revision_notifier.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';

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

class _MutableTagRepository implements TagRepository {
  List<Tag> tags = <Tag>[];

  @override
  Future<List<Tag>> listAll() async => List<Tag>.from(tags);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MutableAuthorRepository implements AuthorRepository {
  List<Author> authors = <Author>[];

  @override
  Future<List<Author>> listAll() async => List<Author>.from(authors);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MutableNamedFacetRepository implements NamedFacetDictionaryRepository {
  List<String> names = <String>[];

  @override
  Future<List<String>> listAll() async => List<String>.from(names);

  @override
  Future<List<String>> listDistinct({String? libraryId}) async =>
      List<String>.from(names);
}

void main() {
  group('librarySearchVocabulary revision refresh', () {
    late StreamController<void> events;
    late _MutableTagRepository tags;
    late _MutableAuthorRepository authors;
    late _MutableNamedFacetRepository parodies;
    late _MutableNamedFacetRepository characters;
    late ProviderContainer container;

    setUp(() {
      events = StreamController<void>.broadcast();
      tags = _MutableTagRepository();
      authors = _MutableAuthorRepository();
      parodies = _MutableNamedFacetRepository();
      characters = _MutableNamedFacetRepository();
      container = ProviderContainer(
        overrides: <Override>[
          libraryRevisionPortProvider.overrideWithValue(
            _FakeLibraryRevisionPort(events),
          ),
          currentLibraryProvider.overrideWith(_FakeCurrentLibraryNotifier.new),
          tagRepoProvider.overrideWithValue(tags),
          authorRepoProvider.overrideWithValue(authors),
          parodyRepoProvider.overrideWithValue(parodies),
          characterRepoProvider.overrideWithValue(characters),
        ],
      );
      container.read(currentLibraryProvider);
      container.read(libraryRevisionProvider);
    });

    tearDown(() async {
      container.dispose();
      await events.close();
    });

    test(
      'after revision bump, newly written facet names parse as exact metadata',
      () async {
        await container.read(currentLibraryProvider.future);

        LibrarySearchVocabulary vocabulary = await container.read(
          librarySearchVocabularyProvider.future,
        );
        expect(vocabulary.tags, isEmpty);
        expect(
          parseLibrarySearchQuery(
            formatLibrarySearchExactMetaQuery('brand-new-tag'),
            knownTagNames: vocabulary.tags,
            knownAuthorNames: vocabulary.authors,
            knownParodyNames: vocabulary.parodies,
            knownCharacterNames: vocabulary.characters,
            knownLanguageNames: vocabulary.languages,
          ),
          isA<LibrarySearchKeywordQuery>(),
        );

        tags.tags = <Tag>[Tag(name: 'brand-new-tag')];
        authors.authors = <Author>[Author(name: 'new-author')];
        parodies.names = <String>['new-parody'];
        characters.names = <String>['new-character'];
        container.read(libraryRevisionProvider.notifier).notifyExternalChange();

        vocabulary = await container.read(
          librarySearchVocabularyProvider.future,
        );

        expect(vocabulary.tags, contains('brand-new-tag'));
        expect(
          parseLibrarySearchQuery(
            formatLibrarySearchExactMetaQuery('brand-new-tag'),
            knownTagNames: vocabulary.tags,
            knownAuthorNames: vocabulary.authors,
            knownParodyNames: vocabulary.parodies,
            knownCharacterNames: vocabulary.characters,
            knownLanguageNames: vocabulary.languages,
          ),
          isA<LibrarySearchMetadataQuery>(),
        );
        expect(
          parseLibrarySearchQuery(
            formatLibrarySearchExactMetaQuery('new-author'),
            knownTagNames: vocabulary.tags,
            knownAuthorNames: vocabulary.authors,
            knownParodyNames: vocabulary.parodies,
            knownCharacterNames: vocabulary.characters,
            knownLanguageNames: vocabulary.languages,
          ),
          isA<LibrarySearchMetadataQuery>(),
        );
        expect(
          parseLibrarySearchQuery(
            formatLibrarySearchExactMetaQuery('new-parody'),
            knownTagNames: vocabulary.tags,
            knownAuthorNames: vocabulary.authors,
            knownParodyNames: vocabulary.parodies,
            knownCharacterNames: vocabulary.characters,
            knownLanguageNames: vocabulary.languages,
          ),
          isA<LibrarySearchMetadataQuery>(),
        );
        expect(
          parseLibrarySearchQuery(
            formatLibrarySearchExactMetaQuery('new-character'),
            knownTagNames: vocabulary.tags,
            knownAuthorNames: vocabulary.authors,
            knownParodyNames: vocabulary.parodies,
            knownCharacterNames: vocabulary.characters,
            knownLanguageNames: vocabulary.languages,
          ),
          isA<LibrarySearchMetadataQuery>(),
        );
        expect(
          parseLibrarySearchQuery(
            formatLibrarySearchExactMetaQuery('Japanese'),
            knownTagNames: vocabulary.tags,
            knownAuthorNames: vocabulary.authors,
            knownParodyNames: vocabulary.parodies,
            knownCharacterNames: vocabulary.characters,
            knownLanguageNames: vocabulary.languages,
          ),
          isA<LibrarySearchMetadataQuery>(),
        );
      },
    );
  });
}
