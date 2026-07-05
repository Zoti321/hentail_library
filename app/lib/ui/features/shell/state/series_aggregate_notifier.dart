import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'series_aggregate_notifier.g.dart';

@Riverpod(keepAlive: true)
Future<List<Series>> allSeries(Ref ref) async {
  final List<Series> list = await ref.watch(librarySeriesRepoProvider).getAll();
  list.sort((Series a, Series b) => a.name.compareTo(b.name));
  return list;
}

/// 系列详情页入口：按 id 单条查询，依赖 [seriesAggregateProvider] 在 sync/编辑后刷新。
@Riverpod(keepAlive: true)
Future<Series?> seriesById(Ref ref, String seriesId) {
  ref.watch(seriesAggregateProvider);
  final String normalizedId = seriesId.trim();
  if (normalizedId.isEmpty) {
    return Future<Series?>.value(null);
  }
  return ref.read(librarySeriesRepoProvider).findById(normalizedId);
}

@Riverpod(keepAlive: true)
class SeriesAggregateNotifier extends _$SeriesAggregateNotifier {
  @override
  int build() => 0;

  void refreshAllSeries() {
    ref.invalidate(allSeriesProvider);
    state += 1;
  }
}
