import 'package:hentai_library/domain/library/comic_deletion_service.dart';
import 'package:hentai_library/ui/features/shell/di/ports.dart';
import 'package:hentai_library/ui/features/shell/di/repos.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'comic_deletion.g.dart';

@Riverpod(keepAlive: true)
ComicDeletionService comicDeletionService(Ref ref) => ComicDeletionService(
  comicRepository: ref.read(comicRepoProvider),
  readingHistoryRepository: ref.read(readingHistoryRepoProvider),
  readerSessionPort: ref.read(readerSessionPortProvider),
);
