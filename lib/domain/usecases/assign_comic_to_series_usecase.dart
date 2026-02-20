import 'package:hentai_library/domain/repository/series_repo.dart';

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
