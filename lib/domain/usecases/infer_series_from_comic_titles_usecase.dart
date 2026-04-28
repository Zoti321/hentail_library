import 'package:hentai_library/data/services/series/auto_series_infer_service.dart';
import 'package:hentai_library/model/entity/comic/comic.dart';
import 'package:hentai_library/model/entity/comic/series.dart';
import 'package:hentai_library/repository/comic_repository.dart';
import 'package:hentai_library/repository/series_repository.dart';

/// [InferSeriesFromComicTitlesUseCase] 执行结果（供 UI 展示）。
final class InferSeriesFromComicTitlesResult {
  const InferSeriesFromComicTitlesResult({
    required this.groupsApplied,
    required this.comicsAssigned,
    required this.newSeriesCreated,
  });

  final int groupsApplied;
  final int comicsAssigned;
  final int newSeriesCreated;
}

class InferSeriesFromComicTitlesUseCase {
  InferSeriesFromComicTitlesUseCase({
    required ComicRepository comicRepository,
    required SeriesRepository seriesRepository,
    required AutoSeriesInferService inferenceService,
  }) : _comicRepository = comicRepository,
       _seriesRepository = seriesRepository,
       _inferenceService = inferenceService;

  final ComicRepository _comicRepository;
  final SeriesRepository _seriesRepository;
  final AutoSeriesInferService _inferenceService;

  Future<InferSeriesFromComicTitlesResult> call() async {
    final List<Series> allSeries = await _seriesRepository.getAll();
    final Set<String> assignedComicIds = <String>{};
    for (final Series s in allSeries) {
      for (final item in s.items) {
        assignedComicIds.add(item.comicId);
      }
    }
    final List<Comic> allComics = await _comicRepository.getAll();
    final List<ComicTitleInput> candidates = <ComicTitleInput>[];
    for (final Comic c in allComics) {
      if (assignedComicIds.contains(c.comicId)) {
        continue;
      }
      candidates.add((comicId: c.comicId, title: c.title));
    }
    final List<InferredSeriesGroup> groups = _inferenceService.inferGroups(
      candidates,
    );
    int comicsAssigned = 0;
    int newSeriesCreated = 0;
    for (final InferredSeriesGroup g in groups) {
      final Series? existingBefore = await _seriesRepository.findByName(
        g.seriesName,
      );
      final bool isNewSeries = existingBefore == null;
      await _seriesRepository.create(g.seriesName);
      if (isNewSeries) {
        newSeriesCreated++;
      }
      final Series? current = await _seriesRepository.findByName(g.seriesName);
      int nextOrder = 0;
      if (current != null && current.items.isNotEmpty) {
        int maxOrder = current.items.first.order;
        for (final item in current.items) {
          if (item.order > maxOrder) {
            maxOrder = item.order;
          }
        }
        nextOrder = maxOrder + 1;
      }
      for (final InferredVolumeEntry e in g.entries) {
        await _seriesRepository.assignComicExclusive(
          comicId: e.comicId,
          targetSeriesName: g.seriesName,
          order: nextOrder,
        );
        nextOrder++;
        comicsAssigned++;
      }
    }
    return InferSeriesFromComicTitlesResult(
      groupsApplied: groups.length,
      comicsAssigned: comicsAssigned,
      newSeriesCreated: newSeriesCreated,
    );
  }
}
