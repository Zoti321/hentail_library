import 'package:hentai_library/domain/use_cases/generate_comic_thumbnails_usecase.dart';
import 'package:hentai_library/ui/features/shell/di/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'generate_comic_thumbnails.g.dart';

@Riverpod(keepAlive: true)
GenerateComicThumbnailsUseCase generateComicThumbnailsUseCase(Ref ref) =>
    GenerateComicThumbnailsUseCase(
      thumbnailService: ref.read(comicThumbnailServiceProvider),
    );
