import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/di/data_providers.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hentai_library/shared/di/library_change_bus.dart';

part 'library_distinct_metadata_providers.g.dart';

@Riverpod(keepAlive: true)
Future<List<String>> libraryDistinctParodies(Ref ref) async {
  ref.watch(
    libraryChangeBusProvider.select(
      (LibraryChangeState s) => s.dictionaryRevision,
    ),
  );
  final String? libraryId = ref
      .watch(currentLibraryStateProvider)
      .asData
      ?.value
      .currentId;
  return ref.watch(parodyRepoProvider).listDistinct(libraryId: libraryId);
}

@Riverpod(keepAlive: true)
Future<List<String>> libraryDistinctCharacters(Ref ref) async {
  ref.watch(
    libraryChangeBusProvider.select(
      (LibraryChangeState s) => s.dictionaryRevision,
    ),
  );
  final String? libraryId = ref
      .watch(currentLibraryStateProvider)
      .asData
      ?.value
      .currentId;
  return ref.watch(characterRepoProvider).listDistinct(libraryId: libraryId);
}
