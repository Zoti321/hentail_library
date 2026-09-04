import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/repositories/named_facet_dictionary_repository.dart';
import 'package:hentai_library/ui/core/widgets/form/character_library_multi_select_field.dart';
import 'package:hentai_library/ui/core/widgets/form/parody_library_multi_select_field.dart';
import 'package:hentai_library/ui/features/shell/di/repos.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;

class _FakeNamedFacetDictionaryRepository
    implements NamedFacetDictionaryRepository {
  _FakeNamedFacetDictionaryRepository({this.all = const <String>[]});

  final List<String> all;

  @override
  Future<List<String>> listAll() async => all;

  @override
  Future<List<String>> listDistinct({String? libraryId}) async => all;
}

void main() {
  test(
    'allParodiesProvider reads listAll through NamedFacetDictionaryRepository',
    () async {
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          parodyRepoProvider.overrideWithValue(
            _FakeNamedFacetDictionaryRepository(
              all: <String>['Fate', 'Touhou'],
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(
        await container.read(allParodiesProvider.future),
        <String>['Fate', 'Touhou'],
      );
    },
  );

  test(
    'allCharactersProvider reads listAll through NamedFacetDictionaryRepository',
    () async {
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          characterRepoProvider.overrideWithValue(
            _FakeNamedFacetDictionaryRepository(all: <String>['Reimu']),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(
        await container.read(allCharactersProvider.future),
        <String>['Reimu'],
      );
    },
  );
}
