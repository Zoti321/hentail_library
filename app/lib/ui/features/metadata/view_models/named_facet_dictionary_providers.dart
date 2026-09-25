import 'package:hentai_library/ui/features/shell/di/repos.dart';
import 'package:riverpod/riverpod.dart';

/// Parody 字典（name ASC），供管理页与非表单调用方使用。
final allParodiesProvider = FutureProvider.autoDispose<List<String>>((Ref ref) {
  return ref.watch(parodyRepoProvider).listAll();
});

/// Character 字典（name ASC），供管理页与非表单调用方使用。
final allCharactersProvider = FutureProvider.autoDispose<List<String>>((
  Ref ref,
) {
  return ref.watch(characterRepoProvider).listAll();
});
