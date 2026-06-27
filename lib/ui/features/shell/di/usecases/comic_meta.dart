import 'package:hentai_library/domain/use_cases/assign_comic_to_series_usecase.dart';
import 'package:hentai_library/domain/use_cases/infer_series_from_comic_titles_usecase.dart';
import 'package:hentai_library/domain/use_cases/update_comic_meta_usecase.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'comic_meta.g.dart';

@Riverpod(keepAlive: true)
UpdateComicMetaUseCase updateComicMetadataUseCase(Ref ref) {
  return UpdateComicMetaUseCase(ref.read(comicRepoProvider));
}

@Riverpod(keepAlive: true)
AssignComicToSeriesUseCase assignLibraryComicToSeriesUseCase(Ref ref) {
  return AssignComicToSeriesUseCase(ref.read(librarySeriesRepoProvider));
}

@Riverpod(keepAlive: true)
InferSeriesFromComicTitlesUseCase inferSeriesFromComicTitlesUseCase(Ref ref) {
  return InferSeriesFromComicTitlesUseCase(
    comicRepository: ref.read(comicRepoProvider),
    seriesRepository: ref.read(librarySeriesRepoProvider),
    inferenceService: ref.read(autoSeriesInferServiceProvider),
  );
}
