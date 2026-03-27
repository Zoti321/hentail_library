import 'package:hentai_library/domain/repository/library_series_repo.dart';

/// v2 用例壳：将漫画排他地加入某系列并设置顺序。
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
