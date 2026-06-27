import 'package:hentai_library/data/mappers/comic/comic_mapper.dart';
import 'package:hentai_library/data/services/comic/scan/comic_scan_parse_service.dart';
import 'package:hentai_library/domain/ports/library_scan_port.dart';

/// [LibraryScanPort] 的 data 层 adapter：扫描 + ParsedResource→Comic 映射。
class ComicLibraryScanAdapter implements LibraryScanPort {
  const ComicLibraryScanAdapter({
    required ComicScanParseService scanParseService,
    required ComicMapper comicMapper,
  }) : _scanParseService = scanParseService,
       _comicMapper = comicMapper;

  final ComicScanParseService _scanParseService;
  final ComicMapper _comicMapper;

  @override
  Stream<LibraryScanItem> scanRoots(
    Iterable<String> roots, {
    bool Function()? isCancelled,
  }) async* {
    await for (final ParsedResource resource in _scanParseService
        .scanAndParseRoots(roots, isCancelled: isCancelled)) {
      yield (
        path: resource.path,
        resourceType: resource.type,
        comic: _comicMapper.fromParsedResource(resource),
      );
    }
  }
}
