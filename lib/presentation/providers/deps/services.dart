import 'package:hentai_library/data/services/comic/comic_resource_getting_service.dart';
import 'package:hentai_library/data/services/comic/comic_scan_parse_service.dart';
import 'package:hentai_library/data/services/comic/resource_parser.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'services.g.dart';

@Riverpod(keepAlive: true)
ParseContext defaultParseContext(Ref ref) => defaultComicParseContext();

@Riverpod(keepAlive: true)
List<ResourceParser> comicResourceParsers(Ref ref) =>
    defaultComicResourceParsers();

@Riverpod(keepAlive: true)
ComicScanParseService comicScanParseService(Ref ref) => ComicScanParseService(
  parsers: ref.read(comicResourceParsersProvider),
  parseContext: ref.read(defaultParseContextProvider),
);

@Riverpod(keepAlive: true)
ComicResourceGettingService comicResourceGettingService(Ref ref) =>
    ComicResourceGettingService();
