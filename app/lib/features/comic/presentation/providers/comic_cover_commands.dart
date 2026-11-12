import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/comic/application/set_comic_cover.dart';
import 'package:hentai_library/features/comic/presentation/providers/comic_cover_providers.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/features/comic/presentation/providers/comic_repository_providers.dart';

/// 漫画封面写入命令签名：消费方（reader 等）只依赖本 typedef，不接触仓储与缓存。
typedef ComicCoverSetCommand = Future<void> Function({
  required String comicId,
  required String path,
  required ResourceType resourceType,
  required int pageIndex,
});

/// 装配 [setComicCoverFromPage]：仓储写入后同步封面缓存，使封面读取面立即生效。
final Provider<ComicCoverSetCommand> comicCoverSetCommandProvider =
    Provider<ComicCoverSetCommand>((Ref ref) {
      return ({
        required String comicId,
        required String path,
        required ResourceType resourceType,
        required int pageIndex,
      }) async {
        final Uint8List? bytes = await setComicCoverFromPage(
          ref.read(comicThumbnailRepoProvider),
          comicId: comicId,
          path: path,
          resourceType: resourceType,
          pageIndex: pageIndex,
        );
        if (bytes != null) {
          ref
              .read(comicCoverThumbnailCacheProvider(comicId).notifier)
              .set(bytes);
        }
      };
    });
