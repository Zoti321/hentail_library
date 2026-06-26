import 'package:hentai_library/services/comic/scan/comic_scan_parse_service.dart';
import 'package:hentai_library/model/entity/comic/comic.dart';
import 'package:hentai_library/module/mapping/mapping.dart';
import 'package:hentai_library/repository/comic_repository.dart';

/// 用例壳：从文件系统扫描并解析资源，然后写入  Comic 仓储。
///
/// 注意：当前仅作为接口层组织者，不接入 DAO/DB；仓储实现后续再补。
class IngestLibraryResourcesUseCase {
  final ComicScanParseService scanParseService;
  final ComicMapper mapper;
  final ComicRepository comicRepo;

  IngestLibraryResourcesUseCase({
    required this.scanParseService,
    required this.mapper,
    required this.comicRepo,
  });

  Future<void> call(
    Iterable<String> roots, {
    bool Function()? isCancelled,
  }) async {
    final comics = <Comic>[];
    await for (final r in scanParseService.scanAndParseRoots(
      roots,
      isCancelled: isCancelled,
    )) {
      if (isCancelled?.call() == true) break;
      comics.add(mapper.fromParsedResource(r));
    }

    await comicRepo.replaceByScan(comics);
  }
}
