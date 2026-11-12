import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/comic_metadata/public/di/comic_metadata_repository_providers.dart';
import 'package:hentai_library/shared/di/domain_event_revisions.dart';
import 'package:hentai_library/features/comic_metadata/public/di/comic_metadata_dictionary_state_providers.dart';
import 'package:hentai_library/features/comic_metadata/public/comic_metadata_entities.dart';

final libraryFilterTagNamesProvider = Provider<AsyncValue<List<String>>>((
  Ref ref,
) {
  return ref
      .watch(libraryTagDictionaryStateProvider)
      .whenData(
        (List<Tag> tags) =>
            tags.map((Tag tag) => tag.name).toList(growable: false),
      );
});

/// 作者筛选的候选值为作者 id（显示名由筛选 UI 的 labelFor 解析）。
final libraryFilterAuthorNamesProvider = Provider<AsyncValue<List<String>>>((
  Ref ref,
) {
  return ref.watch(libraryAuthorDictionaryStateProvider).whenData((
    List<Author> authors,
  ) {
    final List<Author> sorted = List<Author>.of(authors)
      ..sort((Author a, Author b) => a.name.compareTo(b.name));
    return sorted
        .where((Author author) => author.id != null)
        .map((Author author) => '${author.id}')
        .toList();
  });
});

/// 原作筛选候选：全局字典（与标签 / 作者一致，非库内 distinct）。
final libraryFilterParodyNamesProvider = FutureProvider<List<String>>((
  Ref ref,
) async {
  ref.watch(
    domainEventRevisionsProvider.select(
      (DomainEventRevisionsState s) => s.dictionaryRevision,
    ),
  );
  final List<String> names = await ref.watch(parodyRepoProvider).listAll();
  return (List<String>.of(names)..sort());
});

/// 角色筛选候选：全局字典（与标签 / 作者一致，非库内 distinct）。
final libraryFilterCharacterNamesProvider = FutureProvider<List<String>>((
  Ref ref,
) async {
  ref.watch(
    domainEventRevisionsProvider.select(
      (DomainEventRevisionsState s) => s.dictionaryRevision,
    ),
  );
  final List<String> names = await ref.watch(characterRepoProvider).listAll();
  return (List<String>.of(names)..sort());
});
