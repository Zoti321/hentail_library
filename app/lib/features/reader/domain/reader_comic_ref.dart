import 'package:hentai_library/shared/domain/models/enums.dart';

/// 阅读器持有的漫画窄读模型（reader ↛ comic，ADR-0041）。
///
/// 只保留阅读器实际用到的字段：标识、路径、资源类型、页数、标题。
final class ReaderComicRef {
  const ReaderComicRef({
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
