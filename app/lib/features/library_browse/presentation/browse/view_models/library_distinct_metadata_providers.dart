import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/di/data_providers.dart';
import 'package:hentai_library/shared/di/browse_library_scope_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hentai_library/shared/di/domain_event_revisions.dart';

part 'library_distinct_metadata_providers.g.dart';

@Riverpod(keepAlive: true)
Future<List<String>> libraryDistinctParodies(Ref ref) async {
  ref.watch(
    domainEventRevisionsProvider.select(
      (DomainEventRevisionsState s) => s.dictionaryRevision,
    ),
  );
  final String? libraryId = ref.watch(browseLibraryIdProvider);
  return ref.watch(parodyRepoProvider).listDistinct(libraryId: libraryId);
}

@Riverpod(keepAlive: true)
Future<List<String>> libraryDistinctCharacters(Ref ref) async {
  ref.watch(
    domainEventRevisionsProvider.select(
      (DomainEventRevisionsState s) => s.dictionaryRevision,
    ),
  );
  final String? libraryId = ref.watch(browseLibraryIdProvider);
  return ref.watch(characterRepoProvider).listDistinct(libraryId: libraryId);
}
