import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/domain/entity/comic/category_tag.dart';
import 'package:hentai_library/domain/entity/comic/chapter.dart' show Chapter;

part 'comic.freezed.dart';

@freezed
abstract class Comic with _$Comic {
  factory Comic({
    required String id,
    required String title,
    String? coverUrl,
    @Default([]) List<CategoryTag> tags,
    @Default([]) List<Chapter> chapters,
    @Default(false) bool isR18,
    String? description,
    String? status,
    DateTime? firstPublishedAt,
    DateTime? lastUpdatedAt,
    int? totalViews,
  }) = _Comic;

  Comic._();

  int get totalChapterCount => chapters.length;
  int get totalPageCount => chapters.fold<int>(
    0,
    (previousValue, element) => previousValue + element.pageCount,
  );

  /// 使用新的元数据更新漫画（充血行为之一）
  ///
  /// - 只会覆盖非 null 的参数，其他字段保持不变
  Comic withUpdatedMetadata({
    String? title,
    String? description,
    bool? isR18,
    String? status,
    DateTime? firstPublishedAt,
    List<CategoryTag>? tags,
  }) {
    return copyWith(
      title: title ?? this.title,
      description: description ?? this.description,
      isR18: isR18 ?? this.isR18,
      status: status ?? this.status,
      firstPublishedAt: firstPublishedAt ?? this.firstPublishedAt,
      tags: tags ?? this.tags,
    );
  }

  /// 增加阅读次数（默认 +1），最小为 0
  Comic incrementViews([int delta = 1]) {
    final current = totalViews ?? 0;
    final next = current + delta;
    return copyWith(totalViews: next < 0 ? 0 : next);
  }

  /// 判断是否可以与另一部漫画进行归档/合并
  ///
  /// 这里给出一个保守的默认规则：
  /// - R18 状态必须一致
  /// - 标题不能为空
  bool canMergeWith(Comic other) {
    if (title.isEmpty || other.title.isEmpty) return false;
    return true;
  }

  /// 将 [other] 的章节合并到当前漫画，去重后按章节 id 排序
  ///
  /// 只负责组合内存中的聚合，不做任何持久化操作。
  Comic mergeChaptersFrom(Comic other) {
    final all = <String, Chapter>{
      for (final c in chapters) c.id: c,
      for (final c in other.chapters) c.id: c,
    };
    final mergedChapters = all.values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    return copyWith(chapters: mergedChapters);
  }
}
