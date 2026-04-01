import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/entity/comic/series.dart';
import 'package:hentai_library/presentation/providers/deps/deps.dart';

/// 全部系列（含各系列下的漫画归属，用于显示数量）。
final allSeriesProvider = FutureProvider<List<Series>>((ref) async {
  final list = await ref.watch(librarySeriesRepoProvider).getAll();
  list.sort((a, b) => a.name.compareTo(b.name));
  return list;
});

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

class SeriesActions {
  SeriesActions(this._ref);

  final Ref _ref;

  Future<void> create(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    await _ref.read(librarySeriesRepoProvider).create(trimmed);
    _ref.invalidate(allSeriesProvider);
  }

  Future<void> rename(String name, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;
    await _ref
        .read(librarySeriesRepoProvider)
        .rename(name: name, newName: trimmed);
    _ref.invalidate(allSeriesProvider);
  }

  Future<void> delete(String seriesId) async {
    await _ref.read(librarySeriesRepoProvider).delete(seriesId);
    _ref.invalidate(allSeriesProvider);
  }
}

final seriesActionsProvider = Provider<SeriesActions>((ref) {
  return SeriesActions(ref);
});
