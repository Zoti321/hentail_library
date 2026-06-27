import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/ui/features/shell/di/usecases/reading_progress.dart';
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
    final Future<void> saveTask = ref
        .read(saveReadSessionProgressUseCaseProvider)
        .call(
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
}
