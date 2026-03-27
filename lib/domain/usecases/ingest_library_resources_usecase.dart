import 'package:hentai_library/data/services/comic/resource_parser.dart';
import 'package:hentai_library/data/services/comic/resource_scanner.dart';
import 'package:hentai_library/domain/entity/comic/library_comic.dart';
import 'package:hentai_library/domain/mappers/library_comic_mapper.dart';
import 'package:hentai_library/domain/repository/library_comic_repo.dart';

/// v2 用例壳：从文件系统扫描并解析资源，然后写入 v2 Comic 仓储。
///
/// 注意：当前仅作为接口层组织者，不接入 DAO/DB；仓储实现后续再补。
class IngestLibraryResourcesUseCase {
  final ResourceScanner scanner;
  final ResourceParser parser;
  final LibraryComicMapper mapper;
  final LibraryComicRepository comicRepo;

  IngestLibraryResourcesUseCase({
    required this.scanner,
    required this.parser,
    required this.mapper,
    required this.comicRepo,
  });

  Future<void> call(
    Iterable<String> roots, {
    bool Function()? isCancelled,
  }) async {
    final candidates = scanner.scanRoots(roots, isCancelled: isCancelled);
    final parsed = parser.parseAll(candidates);

    final comics = <LibraryComic>[];
    await for (final r in parsed) {
      if (isCancelled?.call() == true) break;
      comics.add(mapper.fromParsedResource(r));
    }

    await comicRepo.upsertMany(comics);
  }
}
