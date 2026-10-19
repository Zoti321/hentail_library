import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/named_metadata/presentation/view_models/named_facet_management_controller.dart';
import 'package:hentai_library/features/named_metadata/presentation/view_models/tag_dictionary_import_controller.dart';
import 'package:hentai_library/features/named_metadata/presentation/view_models/tag_management_notifier.dart';
import 'package:hentai_library/shared/di/data_providers.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/shared/domain/models/tag_dictionary_import_result.dart';
import 'package:hentai_library/shared/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/shared/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/shared/domain/repositories/named_facet_management_repository.dart';
import 'package:hentai_library/shared/domain/repositories/tag_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;

class _SharedTagNames {
  _SharedTagNames(this.names);

  final List<String> names;
}

class _FakeNamedFacetManagementRepository
    implements NamedFacetManagementRepository {
  _FakeNamedFacetManagementRepository(this._tags);

  final _SharedTagNames _tags;

  @override
  Future<List<String>> listAll(ManagedNamedFacetKind kind) async {
    return List<String>.of(_tags.names);
  }

  @override
  Future<PagedResult<String>> fetchPage(
    ManagedNamedFacetKind kind,
    PageRequest request,
  ) async {
    return PagedResult<String>(
      items: List<String>.of(_tags.names),
      totalCount: _tags.names.length,
      page: request.page,
      pageSize: request.pageSize,
    );
  }

  @override
  Future<void> deleteByNames(
    ManagedNamedFacetKind kind,
    List<String> names,
  ) async {
    _tags.names.removeWhere(names.contains);
  }

  @override
  Future<void> add(ManagedNamedFacetKind kind, String name) async {}

  @override
  Future<void> rename(
    ManagedNamedFacetKind kind,
    String oldName,
    String newName,
  ) async {}

  @override
  Future<void> merge(
    ManagedNamedFacetKind kind,
    String sourceName,
    String targetName,
  ) async {}

  @override
  Future<int> countAttachments(ManagedNamedFacetKind kind, String name) async {
    return 0;
  }
}

class _FakeTagRepository implements TagRepository {
  _FakeTagRepository(this._tags);

  final _SharedTagNames _tags;

  @override
  Future<List<Tag>> listAll() async {
    return _tags.names.map((String name) => Tag(name: name)).toList();
  }

  @override
  Future<PagedResult<Tag>> fetchPage(PageRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<void> add(Tag tag) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteByNames(List<String> names) {
    throw UnimplementedError();
  }

  @override
  Future<void> rename(String oldName, String newName) {
    throw UnimplementedError();
  }

  @override
  Future<TagDictionaryImportResult> importTagDictionary(
    List<int> jsonBytes,
  ) async {
    _tags.names.add('gamma');
    return const TagDictionaryImportResult(
      added: 1,
      skippedExisting: 0,
      skippedFilteredOrEmptyOrDedupe: 0,
    );
  }
}

ProviderContainer _container(_SharedTagNames tags) {
  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[
      namedFacetManagementRepoProvider.overrideWithValue(
        _FakeNamedFacetManagementRepository(tags),
      ),
      tagRepoProvider.overrideWithValue(_FakeTagRepository(tags)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test(
    'deleteAll clears the tag page and the tag dictionary together',
    () async {
      final _SharedTagNames tags = _SharedTagNames(<String>['alpha', 'beta']);
      final ProviderContainer container = _container(tags);

      container.read(
        namedFacetManagementControllerProvider(ManagedNamedFacetKind.tag),
      );
      await pumpEventQueue();
      expect(
        container
            .read(
              namedFacetManagementControllerProvider(ManagedNamedFacetKind.tag),
            )
            .totalCount,
        2,
      );
      expect(
        (await container.read(
          allTagsProvider.future,
        )).map((Tag tag) => tag.name),
        <String>['alpha', 'beta'],
      );

      await container
          .read(
            namedFacetManagementControllerProvider(
              ManagedNamedFacetKind.tag,
            ).notifier,
          )
          .deleteAll();

      final NamedFacetManagementState page = container.read(
        namedFacetManagementControllerProvider(ManagedNamedFacetKind.tag),
      );
      expect(page.items, isEmpty);
      expect(page.totalCount, 0);
      expect(await container.read(allTagsProvider.future), isEmpty);
    },
  );

  test('deleteAll removes tags hidden by the current search query', () async {
    final _SharedTagNames tags = _SharedTagNames(<String>['alpha', 'beta']);
    final ProviderContainer container = _container(tags);
    final NamedFacetManagementController controller = container.read(
      namedFacetManagementControllerProvider(
        ManagedNamedFacetKind.tag,
      ).notifier,
    );
    await pumpEventQueue();
    await controller.setQuery('alpha');

    expect(
      container
          .read(
            namedFacetManagementControllerProvider(ManagedNamedFacetKind.tag),
          )
          .items,
      <String>['alpha'],
    );

    await controller.deleteAll();

    final NamedFacetManagementState page = container.read(
      namedFacetManagementControllerProvider(ManagedNamedFacetKind.tag),
    );
    expect(page.items, isEmpty);
    expect(page.totalCount, 0);
    expect(await container.read(allTagsProvider.future), isEmpty);
  });

  test(
    'importing a tag dictionary refreshes the tag page and allTagsProvider',
    () async {
      final _SharedTagNames tags = _SharedTagNames(<String>['alpha']);
      final ProviderContainer container = _container(tags);
      container.read(
        namedFacetManagementControllerProvider(ManagedNamedFacetKind.tag),
      );
      await pumpEventQueue();

      final TagDictionaryImportResult? result = await container
          .read(tagDictionaryImportControllerProvider.notifier)
          .importFromBytes(Uint8List(0));

      expect(result?.added, 1);
      final NamedFacetManagementState page = container.read(
        namedFacetManagementControllerProvider(ManagedNamedFacetKind.tag),
      );
      expect(page.items, <String>['alpha', 'gamma']);
      expect(page.totalCount, 2);
      expect(
        (await container.read(
          allTagsProvider.future,
        )).map((Tag tag) => tag.name),
        <String>['alpha', 'gamma'],
      );
    },
  );
}
