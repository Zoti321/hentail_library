import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/composition/overrides/domain_event_bus_overrides.dart';
import 'package:hentai_library/features/comic_metadata/domain/named_facet_form_candidate.dart';
import 'package:hentai_library/features/comic_metadata/presentation/view_models/named_facet_management_view_model.dart';
import 'package:hentai_library/features/comic_metadata/presentation/view_models/tag_dictionary_import_view_model.dart';
import 'package:hentai_library/features/comic_metadata/presentation/view_models/tag_management_notifier.dart';
import 'package:hentai_library/features/comic_metadata/public/providers/comic_metadata_repository_providers.dart';
import 'package:hentai_library/features/comic_metadata/domain/tag.dart';
import 'package:hentai_library/features/comic_metadata/domain/tag_dictionary_import_result.dart';
import 'package:hentai_library/shared/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/shared/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/features/comic_metadata/domain/named_facet_management_repository.dart';
import 'package:hentai_library/features/comic_metadata/domain/tag_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;

class _SharedTagNames {
  _SharedTagNames(this.names);

  final List<String> names;
  int countAttachmentsCalls = 0;
  int countAttachmentsBatchCalls = 0;
  int listAllCalls = 0;
  int fetchPageCalls = 0;
  int writeCalls = 0;
  Object? writeFailure;
  Object? listAllFailure;
  Future<List<String>> Function()? listAllOverride;
  Future<PagedResult<NamedFacetFormCandidate>> Function(PageRequest)?
  fetchPageOverride;
  Future<Map<String, int>> Function(List<String>)? countsOverride;

  void beforeWrite() {
    writeCalls += 1;
    if (writeFailure case final failure?) throw failure;
  }
}

class _FakeNamedFacetManagementRepository
    implements NamedFacetManagementRepository {
  _FakeNamedFacetManagementRepository(this._tags);

  final _SharedTagNames _tags;

  @override
  Future<List<String>> listAll(ManagedNamedFacetKind kind) async {
    _tags.listAllCalls += 1;
    if (_tags.listAllFailure case final failure?) throw failure;
    if (_tags.listAllOverride case final load?) return load();
    return List<String>.of(_tags.names);
  }

  @override
  Future<PagedResult<NamedFacetFormCandidate>> fetchPage(
    ManagedNamedFacetKind kind,
    PageRequest request,
  ) async {
    _tags.fetchPageCalls += 1;
    if (_tags.fetchPageOverride case final load?) return load(request);
    return PagedResult<NamedFacetFormCandidate>(
      items: <NamedFacetFormCandidate>[
        for (final String name in _tags.names)
          namedFacetFormCandidate(name: name, attachmentCount: 3),
      ],
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
    _tags.beforeWrite();
    _tags.names.removeWhere(names.contains);
  }

  @override
  Future<void> add(ManagedNamedFacetKind kind, String name) async {
    _tags.beforeWrite();
    _tags.names.add(name);
  }

  @override
  Future<void> rename(
    ManagedNamedFacetKind kind,
    String oldName,
    String newName,
  ) async {
    _tags.beforeWrite();
    final int index = _tags.names.indexOf(oldName);
    _tags.names[index] = newName;
  }

  @override
  Future<void> merge(
    ManagedNamedFacetKind kind,
    String sourceName,
    String targetName,
  ) async {
    _tags.beforeWrite();
    _tags.names.remove(sourceName);
  }

  @override
  Future<int> countAttachments(ManagedNamedFacetKind kind, String name) async {
    _tags.countAttachmentsCalls += 1;
    return 0;
  }

  @override
  Future<Map<String, int>> countAttachmentsBatch(
    ManagedNamedFacetKind kind,
    List<String> names,
  ) async {
    _tags.countAttachmentsBatchCalls += 1;
    if (_tags.countsOverride case final load?) return load(names);
    return <String, int>{for (final String name in names) name: 7};
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
      ...domainEventBusOverrides(),
      namedFacetManagementRepoProvider.overrideWithValue(
        _FakeNamedFacetManagementRepository(tags),
      ),
      tagRepoProvider.overrideWithValue(_FakeTagRepository(tags)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

PagedResult<NamedFacetFormCandidate> _page(
  List<String> names, {
  int page = 1,
  int? totalCount,
}) => PagedResult(
  items: [for (final name in names) (name: name, attachmentCount: 3)],
  totalCount: totalCount ?? names.length,
  page: page,
  pageSize: kNamedFacetManagementPageSize,
);

void main() {
  test(
    'importing a tag dictionary refreshes the tag page and allTagsProvider',
    () async {
      final _SharedTagNames tags = _SharedTagNames(<String>['alpha']);
      final ProviderContainer container = _container(tags);
      container.read(
        namedFacetManagementViewModelProvider(ManagedNamedFacetKind.tag),
      );
      await pumpEventQueue();

      final TagDictionaryImportResult? result = await container
          .read(tagDictionaryImportViewModelProvider.notifier)
          .importFromBytes(Uint8List(0));

      expect(result?.added, 1);
      final NamedFacetManagementState page = container.read(
        namedFacetManagementViewModelProvider(ManagedNamedFacetKind.tag),
      );
      expect(page.items, <String>['alpha', 'gamma']);
      expect(page.totalCount, 2);
      expect(
        (await container.read(allTagsProvider.future))
            .map((Tag tag) => tag.name),
        <String>['alpha', 'gamma'],
      );
    },
  );

  test(
    'refresh loads attachment counts from page without N+1 prefetch',
    () async {
      final _SharedTagNames tags = _SharedTagNames(<String>['alpha', 'beta']);
      final ProviderContainer container = _container(tags);
      container.read(
        namedFacetManagementViewModelProvider(ManagedNamedFacetKind.tag),
      );
      await pumpEventQueue();

      final NamedFacetManagementState page = container.read(
        namedFacetManagementViewModelProvider(ManagedNamedFacetKind.tag),
      );
      expect(page.attachmentCounts, <String, int>{'alpha': 3, 'beta': 3});
      expect(tags.countAttachmentsCalls, 0);
      expect(tags.countAttachmentsBatchCalls, 0);
    },
  );

  test('search uses batch counts and caches pinyin snapshot', () async {
    final _SharedTagNames tags = _SharedTagNames(<String>['alpha', 'beta']);
    final ProviderContainer container = _container(tags);
    final NamedFacetManagementViewModel vm = container.read(
      namedFacetManagementViewModelProvider(ManagedNamedFacetKind.tag).notifier,
    );
    await pumpEventQueue();

    await vm.setQuery('alp');
    final NamedFacetManagementState page = container.read(
      namedFacetManagementViewModelProvider(ManagedNamedFacetKind.tag),
    );
    expect(page.items, <String>['alpha']);
    expect(page.attachmentCounts, <String, int>{'alpha': 7});
    expect(tags.countAttachmentsBatchCalls, 1);
    expect(tags.countAttachmentsCalls, 0);
    expect(tags.listAllCalls, 1);

    await vm.setQuery('bet');
    expect(tags.countAttachmentsBatchCalls, 2);
    expect(tags.listAllCalls, 1);
    expect(
      container
          .read(
            namedFacetManagementViewModelProvider(ManagedNamedFacetKind.tag),
          )
          .items,
      <String>['beta'],
    );
  });

  for (final operation in ['add', 'rename', 'delete', 'merge']) {
    test('$operation reloads an active search after the write', () async {
      final tags = _SharedTagNames(<String>['alpha', 'alphabet', 'beta']);
      final container = _container(tags);
      final provider = namedFacetManagementViewModelProvider(
        ManagedNamedFacetKind.tag,
      );
      final vm = container.read(provider.notifier);
      await pumpEventQueue();
      await vm.setQuery('alp');
      expect(container.read(provider).items, ['alpha', 'alphabet']);
      expect(tags.listAllCalls, 1);
      final loadingStates = <NamedFacetManagementState>[];
      container.listen(provider, (previous, next) {
        if (next.isLoading) loadingStates.add(next);
      });

      switch (operation) {
        case 'add':
          await vm.add('alpine');
        case 'rename':
          await vm.rename('alpha', 'alpine');
        case 'delete':
          await vm.delete('alpha');
        case 'merge':
          vm.enterMerge('alphabet');
          vm.toggleMergeSource('alpha');
          await vm.merge(targetName: 'alphabet', sourceNames: ['alpha']);
      }

      final expected = switch (operation) {
        'add' => ['alpha', 'alphabet', 'alpine'],
        'rename' => ['alpine', 'alphabet'],
        _ => ['alphabet'],
      };
      final page = container.read(provider);
      expect(page.query, 'alp');
      expect(page.items, expected);
      expect(page.totalCount, expected.length);
      expect(page.attachmentCounts, {for (final name in expected) name: 7});
      expect(page.error, isNull);
      expect(page.isLoading, isFalse);
      expect(tags.writeCalls, 1);
      expect(tags.listAllCalls, 2);
      expect(tags.fetchPageCalls, 1);
      if (operation == 'merge') {
        expect(page.isMergeMode, isFalse);
        expect(page.mergeSources, isEmpty);
        expect(loadingStates, isNotEmpty);
        expect(loadingStates.first.isMergeMode, isFalse);
        expect(loadingStates.first.mergeSources, isEmpty);
      }

      await vm.setQuery('bet');
      expect(container.read(provider).items, ['alphabet', 'beta']);
      expect(tags.listAllCalls, 2);
    });

    test(
      '$operation failure preserves the search and does not reload',
      () async {
        final tags = _SharedTagNames(<String>['alpha', 'alphabet', 'beta']);
        final container = _container(tags);
        final provider = namedFacetManagementViewModelProvider(
          ManagedNamedFacetKind.tag,
        );
        final vm = container.read(provider.notifier);
        await pumpEventQueue();
        await vm.setQuery('alp');
        if (operation == 'merge') {
          vm.enterMerge('alphabet');
          vm.toggleMergeSource('alpha');
        }
        final before = container.read(provider);
        final failure = StateError('write failed');
        tags.writeFailure = failure;

        final pending = switch (operation) {
          'add' => vm.add('alpine'),
          'rename' => vm.rename('alpha', 'alpine'),
          'delete' => vm.delete('alpha'),
          _ => vm.merge(targetName: 'alphabet', sourceNames: ['alpha']),
        };
        await expectLater(pending, throwsA(same(failure)));

        expect(container.read(provider), same(before));
        expect(tags.names, ['alpha', 'alphabet', 'beta']);
        expect(tags.writeCalls, 1);
        expect(tags.listAllCalls, 1);
        expect(tags.fetchPageCalls, 1);
        expect(tags.countAttachmentsBatchCalls, 1);

        await vm.setQuery('bet');
        expect(container.read(provider).items, ['alphabet', 'beta']);
        expect(tags.listAllCalls, 1);
      },
    );
  }

  test('rename rebuilds pinyin search entries for the new name', () async {
    final tags = _SharedTagNames(<String>['猫咪', '小狗']);
    final container = _container(tags);
    final provider = namedFacetManagementViewModelProvider(
      ManagedNamedFacetKind.tag,
    );
    final vm = container.read(provider.notifier);
    await pumpEventQueue();
    await vm.setQuery('mao');
    expect(container.read(provider).items, ['猫咪']);

    await vm.rename('猫咪', '猫娘');

    expect(container.read(provider).items, ['猫娘']);
    expect(tags.listAllCalls, 2);
    await vm.setQuery('maoniang');
    expect(container.read(provider).items, ['猫娘']);
    await vm.setQuery('maomi');
    expect(container.read(provider).items, isEmpty);
    expect(tags.listAllCalls, 2);
  });

  test('dictionary import refreshes an existing search snapshot', () async {
    final tags = _SharedTagNames(<String>['alpha']);
    final container = _container(tags);
    final provider = namedFacetManagementViewModelProvider(
      ManagedNamedFacetKind.tag,
    );
    final vm = container.read(provider.notifier);
    await pumpEventQueue();
    await vm.setQuery('gam');
    expect(container.read(provider).items, isEmpty);
    expect(tags.listAllCalls, 1);

    await container
        .read(tagDictionaryImportViewModelProvider.notifier)
        .importFromBytes(Uint8List(0));

    expect(container.read(provider).query, 'gam');
    expect(container.read(provider).items, ['gamma']);
    expect(container.read(provider).totalCount, 1);
    expect(tags.listAllCalls, 2);
    expect(
      (await container.read(allTagsProvider.future)).map((tag) => tag.name),
      ['alpha', 'gamma'],
    );
  });

  test(
    'search reload failure preserves a committed write without retry',
    () async {
      final tags = _SharedTagNames(<String>['alpha']);
      final container = _container(tags);
      final provider = namedFacetManagementViewModelProvider(
        ManagedNamedFacetKind.tag,
      );
      final vm = container.read(provider.notifier);
      await pumpEventQueue();
      await vm.setQuery('alp');
      final failure = StateError('list failed after commit');
      tags.listAllFailure = failure;

      await vm.add('alpine');

      final page = container.read(provider);
      expect(tags.names, ['alpha', 'alpine']);
      expect(tags.writeCalls, 1);
      expect(tags.listAllCalls, 2);
      expect(tags.fetchPageCalls, 1);
      expect(page.error, same(failure));
      expect(page.isLoading, isFalse);
      expect(page.query, 'alp');
      expect(page.items, ['alpha']);
    },
  );

  test('an old initial page cannot replace a newer search result', () async {
    final initialPage = Completer<PagedResult<NamedFacetFormCandidate>>();
    final tags = _SharedTagNames(['alpha', 'beta'])
      ..fetchPageOverride = (_) => initialPage.future;
    final container = _container(tags);
    final provider = namedFacetManagementViewModelProvider(
      ManagedNamedFacetKind.tag,
    );
    final vm = container.read(provider.notifier);
    await pumpEventQueue();

    await vm.setQuery('bet');
    final latest = container.read(provider);
    expect(latest.items, ['beta']);
    initialPage.complete(_page(['outdated']));
    await pumpEventQueue();

    expect(container.read(provider).query, 'bet');
    expect(container.read(provider).items, ['beta']);
    expect(container.read(provider).attachmentCounts, {'beta': 7});
    expect(container.read(provider), same(latest));
  });

  test('an old search count response cannot replace a newer query', () async {
    final oldCounts = Completer<Map<String, int>>();
    final tags = _SharedTagNames(['alpha', 'beta'])
      ..countsOverride = (names) => names.contains('alpha')
          ? oldCounts.future
          : Future.value({for (final name in names) name: 7});
    final container = _container(tags);
    final provider = namedFacetManagementViewModelProvider(
      ManagedNamedFacetKind.tag,
    );
    final vm = container.read(provider.notifier);
    await pumpEventQueue();

    final older = vm.setQuery('alp');
    await pumpEventQueue();
    await vm.setQuery('bet');
    final latest = container.read(provider);
    expect(latest.items, ['beta']);
    oldCounts.complete({'alpha': 41});
    await older;

    expect(container.read(provider).query, 'bet');
    expect(container.read(provider).items, ['beta']);
    expect(container.read(provider).attachmentCounts, {'beta': 7});
    expect(container.read(provider), same(latest));
  });

  test(
    'an old initial page failure cannot replace a newer search state',
    () async {
      final initialPage = Completer<PagedResult<NamedFacetFormCandidate>>();
      final tags = _SharedTagNames(['alpha', 'beta'])
        ..fetchPageOverride = (_) => initialPage.future;
      final container = _container(tags);
      final provider = namedFacetManagementViewModelProvider(
        ManagedNamedFacetKind.tag,
      );
      final vm = container.read(provider.notifier);
      await pumpEventQueue();
      await vm.setQuery('bet');
      final latest = container.read(provider);

      initialPage.completeError(StateError('obsolete initial request'));
      await pumpEventQueue();

      expect(container.read(provider).error, isNull);
      expect(container.read(provider).items, ['beta']);
      expect(container.read(provider), same(latest));
    },
  );

  for (final fail in [false, true]) {
    test(
      'an old loadMore ${fail ? 'failure' : 'page'} cannot alter a newer search',
      () async {
        final nextPage = Completer<PagedResult<NamedFacetFormCandidate>>();
        final tags = _SharedTagNames(['alpha', 'beta', 'gamma'])
          ..fetchPageOverride = (request) => request.page == 1
              ? Future.value(_page(['alpha'], totalCount: 3))
              : nextPage.future;
        final container = _container(tags);
        final provider = namedFacetManagementViewModelProvider(
          ManagedNamedFacetKind.tag,
        );
        final vm = container.read(provider.notifier);
        await pumpEventQueue();
        final older = vm.loadMore();
        expect(container.read(provider).isLoadingMore, isTrue);
        await vm.setQuery('bet');
        final latest = container.read(provider);

        if (fail) {
          nextPage.completeError(StateError('obsolete page two'));
        } else {
          nextPage.complete(_page(['gamma'], page: 2, totalCount: 3));
        }
        await older;

        expect(container.read(provider).items, ['beta']);
        expect(container.read(provider).attachmentCounts, {'beta': 7});
        expect(container.read(provider).error, isNull);
        expect(container.read(provider), same(latest));
      },
    );
  }

  test('an older names load cannot replace a newer search response', () async {
    final oldNames = Completer<List<String>>();
    final tags = _SharedTagNames(['alpha', 'beta']);
    tags.listAllOverride = () => tags.listAllCalls == 1
        ? oldNames.future
        : Future.value(List<String>.of(tags.names));
    final container = _container(tags);
    final provider = namedFacetManagementViewModelProvider(
      ManagedNamedFacetKind.tag,
    );
    final vm = container.read(provider.notifier);
    await pumpEventQueue();
    final older = vm.setQuery('alp');
    await pumpEventQueue();
    await vm.setQuery('bet');
    final latest = container.read(provider);

    oldNames.complete(['alpha']);
    await older;

    expect(container.read(provider).items, ['beta']);
    expect(container.read(provider), same(latest));
    await vm.setQuery('alp');
    expect(container.read(provider).items, ['alpha']);
    await vm.setQuery('bet');
    expect(container.read(provider).items, ['beta']);
    expect(container.read(provider).attachmentCounts, {'beta': 7});
    expect(tags.listAllCalls, 2);
  });

  test('a names load started before dictionary invalidation cannot poison the new cache', () async {
    final oldNames = Completer<List<String>>();
    final tags = _SharedTagNames(['alpha']);
    tags.listAllOverride = () => tags.listAllCalls == 1
        ? oldNames.future
        : Future.value(List<String>.of(tags.names));
    final container = _container(tags);
    final provider = namedFacetManagementViewModelProvider(
      ManagedNamedFacetKind.tag,
    );
    final vm = container.read(provider.notifier);
    await pumpEventQueue();
    final older = vm.setQuery('gam');
    await pumpEventQueue();
    tags.names.add('gamma');
    await vm.refreshAfterTagDictionaryChange();
    final latest = container.read(provider);
    expect(latest.items, ['gamma']);

    oldNames.complete(['alpha']);
    await older;

    expect(container.read(provider).items, ['gamma']);
    expect(container.read(provider), same(latest));
    await vm.setQuery('alp');
    expect(container.read(provider).items, ['alpha']);
    await vm.setQuery('gam');
    expect(container.read(provider).items, ['gamma']);
    expect(tags.listAllCalls, 2);
  });

  for (final fail in [false, true]) {
    test(
      'a disposed search ${fail ? 'failure' : 'response'} completes without touching replacement state',
      () async {
        final oldNames = Completer<List<String>>();
        final tags = _SharedTagNames(['alpha', 'beta']);
        final container = _container(tags);
        final provider = namedFacetManagementViewModelProvider(
          ManagedNamedFacetKind.tag,
        );
        final vm = container.read(provider.notifier);
        await pumpEventQueue();
        tags.listAllOverride = () => oldNames.future;
        final older = vm.setQuery('alp');
        await pumpEventQueue();
        container.invalidate(provider);
        tags.listAllOverride = null;
        container.read(provider);
        await pumpEventQueue();
        final replacement = container.read(provider);
        final settled = expectLater(older, completes);

        if (fail) {
          oldNames.completeError(StateError('disposed search'));
        } else {
          oldNames.complete(['outdated']);
        }
        await settled;

        expect(container.read(provider).query, '');
        expect(container.read(provider).items, ['alpha', 'beta']);
        expect(container.read(provider), same(replacement));
      },
    );
  }

  testWidgets(
    'returning to the current query cancels a pending debounced search',
    (tester) async {
      final tags = _SharedTagNames(['alpha', 'beta']);
      final container = _container(tags);
      final provider = namedFacetManagementViewModelProvider(
        ManagedNamedFacetKind.tag,
      );
      final vm = container.read(provider.notifier);
      await tester.pump();
      await vm.setQuery('bet');
      final latest = container.read(provider);
      final listReads = tags.listAllCalls;
      final countReads = tags.countAttachmentsBatchCalls;

      vm.setQueryDebounced('alp');
      vm.setQueryDebounced('bet');
      await tester.pump(kNamedFacetSearchDebounce);

      expect(container.read(provider).query, 'bet');
      expect(container.read(provider).items, ['beta']);
      expect(tags.listAllCalls, listReads);
      expect(tags.countAttachmentsBatchCalls, countReads);
      expect(container.read(provider), same(latest));
    },
  );
}
