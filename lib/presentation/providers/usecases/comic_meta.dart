import 'package:hentai_library/domain/entity/comic/library_tag.dart' as v2;
import 'package:hentai_library/domain/enums/enums.dart';
import 'package:hentai_library/domain/usecases/assign_library_comic_to_series_usecase.dart';
import 'package:hentai_library/domain/usecases/ingest_library_resources_usecase.dart';
import 'package:hentai_library/domain/usecases/update_library_comic_meta_usecase.dart';
import 'package:hentai_library/domain/value_objects/form/comic_metadata_form.dart';
import 'package:hentai_library/presentation/providers/deps/deps.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'comic_meta.g.dart';

@Riverpod(keepAlive: true)
IngestLibraryResourcesUseCase ingestLibraryResourcesUseCase(Ref ref) {
  return IngestLibraryResourcesUseCase(
    scanParseService: ref.read(comicScanParseServiceProvider),
    mapper: ref.read(libraryComicMapperProvider),
    comicRepo: ref.read(libraryComicRepoProvider),
  );
}

@Riverpod(keepAlive: true)
UpdateLibraryComicMetaUseCase updateLibraryComicMetaUseCase(Ref ref) {
  return UpdateLibraryComicMetaUseCase(ref.read(libraryComicRepoProvider));
}

/// UI 表单（[ComicMetadataForm]）与领域 [UpdateLibraryComicMetaUseCase] 之间的桥接。
@Riverpod(keepAlive: true)
UpdateComicMetadataFacadeUseCase updateComicMetadataUseCase(Ref ref) =>
    UpdateComicMetadataFacadeUseCase(ref);

@Riverpod(keepAlive: true)
AssignLibraryComicToSeriesUseCase assignLibraryComicToSeriesUseCase(Ref ref) {
  return AssignLibraryComicToSeriesUseCase(ref.read(librarySeriesRepoProvider));
}

class UpdateComicMetadataFacadeUseCase {
  UpdateComicMetadataFacadeUseCase(this._ref);

  final Ref _ref;

  Future<void> call(String comicId, ComicMetadataForm form) async {
    final useCase = _ref.read(updateLibraryComicMetaUseCaseProvider);
    final tags = form.tags.map((t) => v2.LibraryTag(name: t.name)).toList();
    await useCase.call(
      comicId,
      title: form.title,
      authors: form.authors,
      contentRating: form.isR18 ? ContentRating.r18 : ContentRating.safe,
      tags: tags,
    );
  }
}
