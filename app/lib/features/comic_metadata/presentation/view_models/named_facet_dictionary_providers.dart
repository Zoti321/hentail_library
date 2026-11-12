import 'package:hentai_library/features/comic_metadata/public/providers/comic_metadata_repository_providers.dart';
import 'package:riverpod/riverpod.dart';
import 'package:hentai_library/shared/presentation/providers/domain_event_revisions.dart';

/// Parody 字典（name ASC），供管理页与非表单调用方使用。
final allParodiesProvider = FutureProvider.autoDispose<List<String>>((Ref ref) {
  ref.watch(
    domainEventRevisionsProvider.select(
      (DomainEventRevisionsState s) => s.dictionaryRevision,
    ),
  );
  return ref.watch(parodyRepoProvider).listAll();
});

/// Character 字典（name ASC），供管理页与非表单调用方使用。
final allCharactersProvider = FutureProvider.autoDispose<List<String>>((
  Ref ref,
) {
  ref.watch(
    domainEventRevisionsProvider.select(
      (DomainEventRevisionsState s) => s.dictionaryRevision,
    ),
  );
  return ref.watch(characterRepoProvider).listAll();
});
