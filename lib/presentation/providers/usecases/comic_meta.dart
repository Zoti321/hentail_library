import 'package:hentai_library/domain/entity/comic/tag.dart';
import 'package:hentai_library/domain/util/enums.dart';
import 'package:hentai_library/domain/usecases/assign_comic_to_series_usecase.dart';
import 'package:hentai_library/domain/usecases/infer_series_from_comic_titles_usecase.dart';
import 'package:hentai_library/domain/usecases/ingest_library_resources_usecase.dart';
import 'package:hentai_library/domain/usecases/update_comic_meta_usecase.dart';
import 'package:hentai_library/domain/value_objects/form/comic_metadata_form.dart';
import 'package:hentai_library/presentation/providers/deps/deps.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'comic_meta.g.dart';

@Riverpod(keepAlive: true)
IngestLibraryResourcesUseCase ingestLibraryResourcesUseCase(Ref ref) {
  return IngestLibraryResourcesUseCase(
    scanParseService: ref.read(comicScanParseServiceProvider),
    mapper: ref.read(libraryComicMapperProvider),
    comicRepo: ref.read(comicRepoProvider),
  );
}

@Riverpod(keepAlive: true)
UpdateComicMetaUseCase updateLibraryComicMetaUseCase(Ref ref) {
  return UpdateComicMetaUseCase(ref.read(comicRepoProvider));
}

/// UI 表单（[ComicMetadataForm]）与领域 [UpdateComicMetaUseCase] 之间的桥接。
@Riverpod(keepAlive: true)
UpdateComicMetadataFacadeUseCase updateComicMetadataUseCase(Ref ref) =>
    UpdateComicMetadataFacadeUseCase(ref);

@Riverpod(keepAlive: true)
AssignComicToSeriesUseCase assignLibraryComicToSeriesUseCase(Ref ref) {
  return AssignComicToSeriesUseCase(ref.read(librarySeriesRepoProvider));
}

@Riverpod(keepAlive: true)
InferSeriesFromComicTitlesUseCase inferSeriesFromComicTitlesUseCase(Ref ref) {
  return InferSeriesFromComicTitlesUseCase(
    comicRepository: ref.read(comicRepoProvider),
    seriesRepository: ref.read(librarySeriesRepoProvider),
    inferenceService: ref.read(comicSeriesInferenceFromTitlesServiceProvider),
  );
}

class UpdateComicMetadataFacadeUseCase {
  UpdateComicMetadataFacadeUseCase(this._ref);

  final Ref _ref;

  Future<void> call(String comicId, ComicMetadataForm form) async {
    final useCase = _ref.read(updateLibraryComicMetaUseCaseProvider);
    final tags = form.tags.map((t) => Tag(name: t.name)).toList();
    await useCase.call(
      comicId,
      title: form.title,
      authors: form.authors,
      contentRating: form.isR18 ? ContentRating.r18 : ContentRating.safe,
      tags: tags,
    );
  }
}
