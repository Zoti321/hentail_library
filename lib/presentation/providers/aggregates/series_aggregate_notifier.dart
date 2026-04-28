import 'package:hentai_library/model/entity/comic/series.dart';
import 'package:hentai_library/presentation/providers/deps/deps.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'series_aggregate_notifier.g.dart';

@Riverpod(keepAlive: true)
Future<List<Series>> allSeries(Ref ref) async {
  final List<Series> list = await ref.watch(librarySeriesRepoProvider).getAll();
  list.sort((Series a, Series b) => a.name.compareTo(b.name));
  return list;
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
