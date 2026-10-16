import 'package:hentai_library/features/comic_trash/domain/comic_trash_service.dart';
import 'package:hentai_library/ui/features/shell/di/ports.dart';
import 'package:hentai_library/ui/features/shell/di/repos.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'comic_trash.g.dart';

@Riverpod(keepAlive: true)
ComicTrashService comicTrashService(Ref ref) => ComicTrashService(
  comicRepository: ref.read(comicRepoProvider),
  readerSessionPort: ref.read(readerSessionPortProvider),
);
