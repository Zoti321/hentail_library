import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/domain/entity/entities.dart';
import 'package:hentai_library/domain/enums/enums.dart';

part 'comic_filter.freezed.dart';

@freezed
abstract class ComicFilter with _$ComicFilter {
  factory ComicFilter({
    String? query, // 搜索关键词
    Set<CategoryTag>? tags, // 选中的标签
    String? status, // 状态 (如: "连载中", "已完结")
    @Default(false) bool showR18, // 是否显示成人内容
    int? minChapters, // 最少章节数
    Set<ComicImageSourceType>? imageSourceTypes, // 图源类型
  }) = _ComicFilter;

  ComicFilter._();

  /// 判断该漫画是否满足当前筛选条件。
  bool matches(Comic comic) {
    // 1. 关键词搜索（标题或描述）
    if (query != null && query!.isNotEmpty) {
      final q = query!.toLowerCase();
      final matchTitle = comic.title.toLowerCase().contains(q);
      final matchDesc = comic.description?.toLowerCase().contains(q) ?? false;
      if (!matchTitle && !matchDesc) return false;
    }

    // 2. R18 过滤：不显示 R18 时剔除 isR18 为 true 的
    if (showR18 == false && comic.isR18) return false;

    // 3. 标签过滤：漫画须包含所有选中标签
    if (tags != null && tags!.isNotEmpty) {
      final comicTagNames = comic.tags.map((t) => t.name).toSet();
      final filterTagNames = tags!.map((t) => t.name).toSet();
      if (!comicTagNames.containsAll(filterTagNames)) return false;
    }

    // 4. 状态过滤
    if (status != null && comic.status != status) return false;

    // 5. 章节数过滤
    if (minChapters != null && comic.totalChapterCount < minChapters!) {
      return false;
    }

    return true;
  }
}
