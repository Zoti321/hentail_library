import 'package:hentai_library/shared/domain/models/enums.dart';

/// 阅读会话所需的漫画元数据窄读模型（不含 Comic 实体，ADR-0041）。
///
/// reader 只经本 Port 取元数据，避免 `reader → comic` 的禁止边（ADR-0036）。
final class ComicReadSnapshot {
  const ComicReadSnapshot({
    required this.comicId,
    required this.path,
    required this.resourceType,
    required this.pageCount,
    required this.title,
  });

  final String comicId;
  final String path;
  final ResourceType resourceType;
  final int pageCount;
  final String title;
}

/// 阅读器读取漫画元数据的只读口：实现留在 comic，真源留 shared（ADR-0045）。
abstract class ComicReadLookupPort {
  Future<ComicReadSnapshot?> findById(String comicId);

  /// 展示标题（缺失时回落为截断 comicId）。
  Future<String> displayTitleById(String comicId);

  /// 批量展示标题，键集合与入参顺序一致。
  Future<Map<String, String>> displayTitlesByIds(List<String> comicIds);
}
