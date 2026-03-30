import 'package:hentai_library/domain/repository/library_series_repo.dart';

class AssignLibraryComicToSeriesUseCase {
  final LibrarySeriesRepository repo;

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
