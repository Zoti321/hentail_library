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

  Comic incrementViews([int delta = 1]) {
    final current = totalViews ?? 0;
    final next = current + delta;
    return copyWith(totalViews: next < 0 ? 0 : next);
  }

  bool canMergeWith(Comic other) {
    if (title.isEmpty || other.title.isEmpty) return false;
    return true;
  }

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
