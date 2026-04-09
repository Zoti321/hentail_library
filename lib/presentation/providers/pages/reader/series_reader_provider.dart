import 'package:hentai_library/domain/entity/comic/series.dart';
import 'package:hentai_library/domain/entity/series_reading_history.dart';
import 'package:hentai_library/presentation/providers/deps/deps.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'series_reader_provider.g.dart';

/// Loads a [Series] by name for reader navigation (series read mode).
@riverpod
Future<Series?> seriesByNameForReader(Ref ref, String seriesName) async {
  if (seriesName.isEmpty) {
    return null;
  }
  return ref.read(librarySeriesRepoProvider).findByName(seriesName);
}

@riverpod
Future<SeriesReadingHistory?> seriesReadingProgressForReader(
  Ref ref,
  String seriesName,
) async {
  if (seriesName.isEmpty) {
    return null;
  }
  return ref
      .read(readingHistoryRepoProvider)
      .getSeriesReadingBySeriesName(seriesName);
}
