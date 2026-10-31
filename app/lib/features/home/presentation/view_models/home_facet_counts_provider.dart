import 'package:hentai_library/shared/di/data_providers.dart';
import 'package:hentai_library/shared/di/library_change_bus.dart';
import 'package:riverpod/riverpod.dart';

/// 首页聚合统计中的原作与角色数量（字典条目数，与管理页口径一致）。
typedef HomeFacetCounts = ({int parodyCount, int characterCount});

/// 首页原作 / 角色计数：字典变更（导入、清空、增删）时刷新。
final homeFacetCountsProvider = FutureProvider.autoDispose<HomeFacetCounts>((
  Ref ref,
) async {
  ref.watch(
    libraryChangeBusProvider.select(
      (LibraryChangeState s) => s.dictionaryRevision,
    ),
  );
  final List<String> parodies = await ref.watch(parodyRepoProvider).listAll();
  final List<String> characters = await ref
      .watch(characterRepoProvider)
      .listAll();
  return (parodyCount: parodies.length, characterCount: characters.length);
});
