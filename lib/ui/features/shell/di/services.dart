import 'package:hentai_library/data/services/app_update/app_update_service.dart';
import 'package:hentai_library/data/services/comic/thumbnail/comic_thumbnail_service.dart';
import 'package:hentai_library/data/services/comic/content_rating/auto_detect_comic_content_rating_service.dart';
import 'package:hentai_library/data/services/comic/read_resource_get/api/read_resource_get_service.dart';
import 'package:hentai_library/data/services/comic/read_resource_get/internal/open/comic_read_resource_opener.dart';
import 'package:hentai_library/data/services/comic/read_resource_get/internal/session/comic_read_resource_session_manager.dart';
import 'package:hentai_library/data/services/comic/read_resource_get/internal/utils/comic_read_path_normalizer.dart';
import 'package:hentai_library/data/services/comic/scan/comic_scan_parse_service.dart';
import 'package:hentai_library/data/services/comic/scan/resource_parser.dart';
import 'package:hentai_library/domain/library/auto_series_infer_service.dart';
import 'package:hentai_library/ui/features/shell/di/repos.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'services.g.dart';

@Riverpod(keepAlive: true)
AppUpdateService appUpdateService(Ref ref) => AppUpdateService();

@Riverpod(keepAlive: true)
List<ResourceParser> comicResourceParsers(Ref ref) =>
    defaultComicResourceParsers();

@Riverpod(keepAlive: true)
ComicScanParseService comicScanParseService(Ref ref) =>
    ComicScanParseService(parsers: ref.read(comicResourceParsersProvider));

@Riverpod(keepAlive: true)
AutoSeriesInferService autoSeriesInferService(Ref ref) =>
    const AutoSeriesInferService();

@Riverpod(keepAlive: true)
AutoDetectComicContentRatingService autoDetectComicContentRatingService(
  Ref ref,
) => AutoDetectComicContentRatingService(
  comicRepository: ref.read(comicRepoProvider),
);

@Riverpod(keepAlive: true)
ComicReadResourceOpener comicReadResourceOpener(Ref ref) =>
    ComicReadResourceOpener(
      pathNormalizer: ref.read(comicReadPathNormalizerProvider),
    );

@Riverpod(keepAlive: true)
ComicReadPathNormalizer comicReadPathNormalizer(Ref ref) =>
    const ComicReadPathNormalizer();

@Riverpod(keepAlive: true)
ComicReadResourceSessionManager comicReadResourceSessionManager(Ref ref) =>
    ComicReadResourceSessionManager(
      opener: ref.read(comicReadResourceOpenerProvider),
      pathNormalizer: ref.read(comicReadPathNormalizerProvider),
    );

@Riverpod(keepAlive: true)
ReadResourceGetService readResourceGetService(Ref ref) =>
    DefaultReadResourceGetService(
      sessions: ref.read(comicReadResourceSessionManagerProvider),
    );

@Riverpod(keepAlive: true)
ComicThumbnailService comicThumbnailService(Ref ref) =>
    ComicThumbnailService(ref.read(comicThumbnailRepoProvider));
