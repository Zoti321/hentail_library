import 'package:hentai_library/model/entity/comic/comic.dart';
import 'package:hentai_library/model/models.dart' as entity;
import 'package:hentai_library/presentation/providers/usecases/sync_library.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reading_aggregate_notifier.g.dart';

@Riverpod(keepAlive: true)
class ReadingAggregateNotifier extends _$ReadingAggregateNotifier {
  final Map<String, Future<void>> _savingProgressByComic =
      <String, Future<void>>{};
  @override
  int build() => 0;

  Future<void> saveProgress({
    required String comicId,
    required Comic comic,
    required int pageIndex,
    required bool isSeriesMode,
    required String? seriesName,
  }) async {
    final Future<void>? inFlightSave = _savingProgressByComic[comicId];
    if (inFlightSave != null) {
      await inFlightSave;
      return;
    }
    final Future<void> saveTask = _saveProgress(
      comicId: comicId,
      comic: comic,
      pageIndex: pageIndex,
      isSeriesMode: isSeriesMode,
      seriesName: seriesName,
    );
    _savingProgressByComic[comicId] = saveTask;
    try {
      await saveTask;
    } finally {
      _savingProgressByComic.remove(comicId);
    }
  }

  Future<void> _saveProgress({
    required String comicId,
    required Comic comic,
    required int pageIndex,
    required bool isSeriesMode,
    required String? seriesName,
  }) async {
    final DateTime now = DateTime.now();
    final String? validSeriesName = isSeriesMode ? seriesName : null;
    final entity.SeriesReadingHistory? series =
        validSeriesName != null && validSeriesName.isNotEmpty
        ? entity.SeriesReadingHistory(
            seriesName: validSeriesName,
            lastReadComicId: comicId,
            lastReadTime: now,
            pageIndex: pageIndex,
          )
        : null;
    await ref
        .read(recordReadingProgressUseCaseProvider)
        .call(
          entity.ReadingHistory(
            comicId: comicId,
            title: comic.title,
            lastReadTime: now,
            pageIndex: pageIndex,
          ),
          series: series,
        );
  }
}
