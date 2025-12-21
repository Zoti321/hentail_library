import 'package:hentai_library/domain/use_cases/delete_comics_usecase.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'delete_comics.g.dart';

@Riverpod(keepAlive: true)
DeleteComicsUseCase deleteComicsUseCase(Ref ref) => DeleteComicsUseCase(
  comicRepository: ref.read(comicRepoProvider),
  readingHistoryRepository: ref.read(readingHistoryRepoProvider),
  seriesRepository: ref.read(librarySeriesRepoProvider),
  readerSessionPort: ref.read(readerSessionPortProvider),
);
