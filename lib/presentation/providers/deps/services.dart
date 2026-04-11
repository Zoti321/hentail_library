import 'package:hentai_library/data/services/comic/comic_resource_content_handler.dart';
import 'package:hentai_library/data/services/comic/comic_resource_getting_service.dart';
import 'package:hentai_library/data/services/comic/comic_scan_parse_service.dart';
import 'package:hentai_library/data/services/comic/resource_parser.dart';
import 'package:hentai_library/data/services/series/comic_series_inference_from_titles_service.dart';
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
List<ComicResourceContentHandler> comicResourceContentHandlers(Ref ref) =>
    defaultComicResourceContentHandlers();

@Riverpod(keepAlive: true)
ComicResourceGettingService comicResourceGettingService(Ref ref) =>
    ComicResourceGettingService(
      handlers: ref.read(comicResourceContentHandlersProvider),
    );

@Riverpod(keepAlive: true)
ComicSeriesInferenceFromTitlesService comicSeriesInferenceFromTitlesService(
  Ref ref,
) => const ComicSeriesInferenceFromTitlesService();
