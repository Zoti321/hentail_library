import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/presentation/providers/aggregates/series_aggregate_notifier.dart';
import 'package:hentai_library/presentation/providers/deps/deps.dart';

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
