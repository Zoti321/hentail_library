import 'package:hentai_library/domain/repositories/series_repository.dart';

class AssignComicToSeriesUseCase {
  final SeriesRepository repo;

  AssignComicToSeriesUseCase(this.repo);

  Future<void> call({
    required String comicId,
    required String targetSeriesName,
    required int order,
  }) {
    return repo.assignComicExclusive(
      comicId: comicId,
      targetSeriesName: targetSeriesName,
      order: order,
    );
  }
}
