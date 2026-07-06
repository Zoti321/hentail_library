import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';

part 'library_comic_sort_option.freezed.dart';

enum LibraryComicSortField {
  title,
  createdAt,
  lastUpdatedAt,
  publishedAt,
  readAt,
  fileSize,
  pageCount,
}

extension LibraryComicSortFieldX on LibraryComicSortField {
  String get label => switch (this) {
    LibraryComicSortField.title => '标题',
    LibraryComicSortField.createdAt => '添加时间',
    LibraryComicSortField.lastUpdatedAt => '更新时间',
    LibraryComicSortField.publishedAt => '发布日期',
    LibraryComicSortField.readAt => '阅读日期',
    LibraryComicSortField.fileSize => '文件大小',
    LibraryComicSortField.pageCount => '页数',
  };

  bool get isImplemented => true;
}

@freezed
abstract class LibraryComicSortOption with _$LibraryComicSortOption {
  factory LibraryComicSortOption({
    @Default(LibraryComicSortField.title) LibraryComicSortField field,
    @Default(false) bool descending,
  }) = _LibraryComicSortOption;

  const LibraryComicSortOption._();

  int compare(Comic a, Comic b) {
    int result;
    switch (field) {
      case LibraryComicSortField.title:
        result = a.title.compareTo(b.title);
      case LibraryComicSortField.createdAt:
        result = a.createdAt.compareTo(b.createdAt);
      case LibraryComicSortField.lastUpdatedAt:
        result = a.lastUpdatedAt.compareTo(b.lastUpdatedAt);
      case LibraryComicSortField.publishedAt:
        result = _compareOptionalDate(a.publishedAt, b.publishedAt);
      case LibraryComicSortField.readAt:
        result = a.title.compareTo(b.title);
      case LibraryComicSortField.fileSize:
        result = a.resourceSize.compareTo(b.resourceSize);
      case LibraryComicSortField.pageCount:
        result = a.pageCount.compareTo(b.pageCount);
    }
    return descending ? -result : result;
  }

  int _compareOptionalDate(DateTime? left, DateTime? right) {
    if (left == null && right == null) {
      return 0;
    }
    if (left == null) {
      return 1;
    }
    if (right == null) {
      return -1;
    }
    return left.compareTo(right);
  }
}
