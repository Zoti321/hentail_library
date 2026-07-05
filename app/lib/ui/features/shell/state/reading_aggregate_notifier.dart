import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/reading_history.dart';
import 'package:hentai_library/ui/features/shell/di/repos.dart';
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
    required String? seriesId,
  }) async {
    final Future<void>? inFlightSave = _savingProgressByComic[comicId];
    if (inFlightSave != null) {
      await inFlightSave;
      return;
    }
    final Future<void> saveTask = _persistProgress(
      comic: comic,
      pageIndex: pageIndex,
    );
    _savingProgressByComic[comicId] = saveTask;
    try {
      await saveTask;
    } finally {
      _savingProgressByComic.remove(comicId);
    }
  }

  Future<void> _persistProgress({
    required Comic comic,
    required int pageIndex,
  }) async {
    final DateTime now = DateTime.now();
    await ref
        .read(readingHistoryRepoProvider)
        .recordReading(
          ReadingHistory(
            comicId: comic.comicId,
            title: comic.title,
            lastReadTime: now,
            pageIndex: pageIndex,
          ),
        );
  }
}
