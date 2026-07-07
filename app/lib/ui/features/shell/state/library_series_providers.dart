import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:hentai_library/ui/features/shell/state/library_revision_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'library_series_providers.g.dart';

@Riverpod(keepAlive: true)
Future<List<Series>> allSeries(Ref ref) async {
  ref.watch(
    libraryRevisionProvider.select((LibraryRevisionState s) => s.revision),
  );
  final List<Series> list = await ref.watch(seriesRepoProvider).getAll();
  list.sort((Series a, Series b) => a.name.compareTo(b.name));
  return list;
}

/// 系列详情页入口：按 id 单条查询，依赖 [libraryRevisionProvider] 在 sync/编辑后刷新。
@Riverpod(keepAlive: true)
Future<Series?> seriesById(Ref ref, String seriesId) {
  ref.watch(
    libraryRevisionProvider.select((LibraryRevisionState s) => s.revision),
  );
  final String normalizedId = seriesId.trim();
  if (normalizedId.isEmpty) {
    return Future<Series?>.value(null);
  }
  return ref.read(seriesRepoProvider).findById(normalizedId);
}
