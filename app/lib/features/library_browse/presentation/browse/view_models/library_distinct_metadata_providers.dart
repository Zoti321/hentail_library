import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/presentation/providers/browse_library_scope_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hentai_library/shared/presentation/providers/domain_event_revisions.dart';
import 'package:hentai_library/features/comic_metadata/public/providers/comic_metadata_repository_providers.dart';

part 'library_distinct_metadata_providers.g.dart';

@Riverpod(keepAlive: true)
Future<List<String>> libraryDistinctParodies(Ref ref) {
  ref.watch(
    domainEventRevisionsProvider.select(
      (DomainEventRevisionsState s) => s.dictionaryRevision,
    ),
  );
  final String? libraryId = ref.watch(browseLibraryIdProvider);
  return ref.watch(parodyRepoProvider).listDistinct(libraryId: libraryId);
}

@Riverpod(keepAlive: true)
Future<List<String>> libraryDistinctCharacters(Ref ref) {
  ref.watch(
    domainEventRevisionsProvider.select(
      (DomainEventRevisionsState s) => s.dictionaryRevision,
    ),
  );
  final String? libraryId = ref.watch(browseLibraryIdProvider);
  return ref.watch(characterRepoProvider).listDistinct(libraryId: libraryId);
}
