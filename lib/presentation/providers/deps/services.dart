import 'package:hentai_library/data/services/comic/read_resource_get/comic_read_resource_opener.dart';
import 'package:hentai_library/data/services/comic/read_resource_get/comic_read_resource_session_manager.dart';
import 'package:hentai_library/data/services/comic/scan/comic_scan_parse_service.dart';
import 'package:hentai_library/data/services/comic/scan/resource_parser.dart';
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
ComicSeriesInferenceFromTitlesService comicSeriesInferenceFromTitlesService(
  Ref ref,
) => const ComicSeriesInferenceFromTitlesService();

@Riverpod(keepAlive: true)
ComicReadResourceOpener comicReadResourceOpener(Ref ref) =>
    ComicReadResourceOpener();

@Riverpod(keepAlive: true)
ComicReadResourceSessionManager comicReadResourceSessionManager(Ref ref) =>
    ComicReadResourceSessionManager(
      opener: ref.read(comicReadResourceOpenerProvider),
    );
