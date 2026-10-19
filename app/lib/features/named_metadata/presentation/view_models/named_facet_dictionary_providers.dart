import 'package:hentai_library/shared/di/data_providers.dart';
import 'package:riverpod/riverpod.dart';
import 'package:hentai_library/shared/di/library_change_bus.dart';

/// Parody 字典（name ASC），供管理页与非表单调用方使用。
final allParodiesProvider = FutureProvider.autoDispose<List<String>>((Ref ref) {
  ref.watch(
    libraryChangeBusProvider.select(
      (LibraryChangeState s) => s.dictionaryRevision,
    ),
  );
  return ref.watch(parodyRepoProvider).listAll();
});

/// Character 字典（name ASC），供管理页与非表单调用方使用。
final allCharactersProvider = FutureProvider.autoDispose<List<String>>((
  Ref ref,
) {
  ref.watch(
    libraryChangeBusProvider.select(
      (LibraryChangeState s) => s.dictionaryRevision,
    ),
  );
  return ref.watch(characterRepoProvider).listAll();
});
