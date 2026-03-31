import 'package:hentai_library/domain/repository/series_repo.dart';

class AssignLibraryComicToSeriesUseCase {
  final SeriesRepository repo;

  AssignLibraryComicToSeriesUseCase(this.repo);

  Future<void> call({
    required String comicId,
    required String targetSeriesId,
    required int order,
  }) {
    return repo.assignComicExclusive(
      comicId: comicId,
      targetSeriesId: targetSeriesId,
      order: order,
    );
  }
}
