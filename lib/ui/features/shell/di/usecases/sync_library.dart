import 'package:hentai_library/domain/use_cases/sync_library_usecase.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:hentai_library/ui/features/shell/di/usecases/delete_comics.dart';
import 'package:hentai_library/ui/features/shell/di/usecases/generate_comic_thumbnails.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sync_library.g.dart';

@Riverpod(keepAlive: true)
SyncLibraryUseCase syncLibraryUseCase(Ref ref) => SyncLibraryUseCase(
  pathRepository: ref.read(pathRepoProvider),
  comicRepository: ref.read(comicRepoProvider),
  comicThumbnailRepository: ref.read(comicThumbnailRepoProvider),
  deleteComicsUseCase: ref.read(deleteComicsUseCaseProvider),
  generateComicThumbnailsUseCase: ref.read(
    generateComicThumbnailsUseCaseProvider,
  ),
  libraryScanPort: ref.read(libraryScanPortProvider),
  readerSessionPort: ref.read(readerSessionPortProvider),
);
