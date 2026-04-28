import 'package:hentai_library/services/comic/cache/archive_cover_cache.dart';
import 'package:hentai_library/services/comic/cache/archive_cover_disk_cache.dart';
import 'package:hentai_library/services/comic/content_rating/auto_detect_comic_content_rating_service.dart';
import 'package:hentai_library/services/comic/read_resource_get/api/read_resource_get_service.dart';
import 'package:hentai_library/services/comic/read_resource_get/internal/open/comic_read_resource_opener.dart';
import 'package:hentai_library/services/comic/read_resource_get/internal/session/comic_read_resource_session_manager.dart';
import 'package:hentai_library/services/comic/read_resource_get/internal/utils/comic_read_path_normalizer.dart';
import 'package:hentai_library/model/app_setting.dart';
import 'package:hentai_library/presentation/providers/pages/settings/settings_notifier.dart';
import 'package:hentai_library/services/comic/scan/comic_scan_parse_service.dart';
import 'package:hentai_library/services/comic/scan/resource_parser.dart';
import 'package:hentai_library/presentation/providers/deps/database_dao.dart';
import 'package:hentai_library/services/series/auto_series_infer_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'services.g.dart';

@Riverpod(keepAlive: true)
List<ResourceParser> comicResourceParsers(Ref ref) =>
    defaultComicResourceParsers();

@Riverpod(keepAlive: true)
ComicScanParseService comicScanParseService(Ref ref) => ComicScanParseService(
  parsers: ref.read(comicResourceParsersProvider),
);

@Riverpod(keepAlive: true)
AutoSeriesInferService autoSeriesInferService(Ref ref) =>
    const AutoSeriesInferService();

@Riverpod(keepAlive: true)
AutoDetectComicContentRatingService autoDetectComicContentRatingService(
  Ref ref,
) => AutoDetectComicContentRatingService(comicDao: ref.read(comicDaoProvider));

@Riverpod(keepAlive: true)
ComicReadResourceOpener comicReadResourceOpener(Ref ref) =>
    ComicReadResourceOpener(pathNormalizer: ref.read(comicReadPathNormalizerProvider));

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

/// 是否启用归档封面磁盘缓存（与 [AppSetting.archiveCoverDiskCacheEnabled] 一致）。
@Riverpod(keepAlive: true)
bool archiveCoverDiskCacheEnabled(Ref ref) {
  final AsyncValue<AppSetting> async = ref.watch(settingsProvider);
  return async.maybeWhen(
    data: (AppSetting s) => s.archiveCoverDiskCacheEnabled,
    orElse: () => true,
  );
}

@Riverpod(keepAlive: true)
ArchiveCoverCache archiveCoverCache(Ref ref) => ArchiveCoverDiskCache();

/// 归档封面在应用缓存目录中的占用（字节）。
@Riverpod(keepAlive: true)
Future<int> archiveCoverCacheDiskUsageBytes(Ref ref) async {
  final ArchiveCoverCache cache = ref.watch(archiveCoverCacheProvider);
  return cache.totalBytesInCache();
}
