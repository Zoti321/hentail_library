import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/ui/features/shell/state/series_aggregate_notifier.dart';

/// 系列名称筛选关键词
class SeriesFilterNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String value) {
    state = value;
  }

  void clear() {
    state = '';
  }
}

final seriesFilterProvider = NotifierProvider<SeriesFilterNotifier, String>(
  SeriesFilterNotifier.new,
);

final filteredSeriesProvider = Provider<AsyncValue<List<Series>>>((ref) {
  final AsyncValue<List<Series>> asyncSeries = ref.watch(allSeriesProvider);
  final String query = ref.watch(seriesFilterProvider).trim().toLowerCase();
  return asyncSeries.whenData((List<Series> list) {
    if (query.isEmpty) {
      return list;
    }
    return list
        .where((Series item) => item.name.toLowerCase().contains(query))
        .toList();
  });
});
