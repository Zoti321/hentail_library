import 'package:hentai_library/shared/domain/models/enums.dart';

import 'dart:typed_data';

import 'package:hentai_library/features/comic/domain/repositories/comic_thumbnail_repository.dart';

/// 以漫画指定页（0-based）设为封面，返回写入后的封面位图（无则 `null`）。
///
/// 命令真源在 comic 模块（ADR-0033 / ADR-0039）；封面缓存刷新属 presentation /
/// DI 关注点，由调用方据返回值处理，本层不触碰 Riverpod 与 Flutter。
Future<Uint8List?> setComicCoverFromPage(
  ComicThumbnailRepository repository, {
  required String comicId,
  required String path,
  required ResourceType resourceType,
  required int pageIndex,
}) async {
  await repository.setComicCoverFromPage(
    comicId: comicId,
    path: path,
    resourceType: resourceType,
    pageIndex: pageIndex,
  );
  final record = await repository.findByComicId(comicId);
  final Uint8List? bytes = record?.thumbnail;
  return (bytes == null || bytes.isEmpty) ? null : bytes;
}
