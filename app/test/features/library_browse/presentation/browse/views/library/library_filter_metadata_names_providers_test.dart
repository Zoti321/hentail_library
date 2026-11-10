import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/bootstrap/di/overrides/domain_event_bus_overrides.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_filter_metadata_names_providers.dart';
import 'package:hentai_library/features/named_metadata/domain/named_facet_dictionary_repository.dart';
import 'package:hentai_library/shared/di/data_providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;

class _FakeNamedFacetDictionaryRepository
    implements NamedFacetDictionaryRepository {
  _FakeNamedFacetDictionaryRepository({this.all = const <String>[]});

  final List<String> all;

  @override
  Future<List<String>> listAll() async => all;

  @override
  Future<List<String>> listDistinct({String? libraryId}) async =>
      const <String>[];
}

void main() {
  test('libraryFilterParodyNamesProvider reads sorted listAll', () async {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        ...domainEventBusOverrides(),
        parodyRepoProvider.overrideWithValue(
          _FakeNamedFacetDictionaryRepository(all: <String>['Touhou', 'Fate']),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(
      await container.read(libraryFilterParodyNamesProvider.future),
      <String>['Fate', 'Touhou'],
    );
  });

  test('libraryFilterCharacterNamesProvider reads sorted listAll', () async {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        ...domainEventBusOverrides(),
        characterRepoProvider.overrideWithValue(
          _FakeNamedFacetDictionaryRepository(all: <String>['Reimu', 'Marisa']),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(
      await container.read(libraryFilterCharacterNamesProvider.future),
      <String>['Marisa', 'Reimu'],
    );
  });

  test('empty dictionary yields empty candidate list', () async {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        ...domainEventBusOverrides(),
        parodyRepoProvider.overrideWithValue(
          _FakeNamedFacetDictionaryRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(
      await container.read(libraryFilterParodyNamesProvider.future),
      isEmpty,
    );
  });
}
