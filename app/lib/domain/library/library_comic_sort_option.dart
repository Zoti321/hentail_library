import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';

part 'library_comic_sort_option.freezed.dart';

enum LibraryComicSortField {
  title,
  createdAt,
  updatedAt,
  publishedAt,
  readAt,
  fileSize,
  pageCount,
}

extension LibraryComicSortFieldX on LibraryComicSortField {
  String get label => switch (this) {
    LibraryComicSortField.title => '标题',
    LibraryComicSortField.createdAt => '添加时间',
    LibraryComicSortField.updatedAt => '更新时间',
    LibraryComicSortField.publishedAt => '发布日期',
    LibraryComicSortField.readAt => '阅读日期',
    LibraryComicSortField.fileSize => '文件大小',
    LibraryComicSortField.pageCount => '页数',
  };

  bool get isImplemented => this == LibraryComicSortField.title;
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
      case LibraryComicSortField.updatedAt:
      case LibraryComicSortField.publishedAt:
      case LibraryComicSortField.readAt:
      case LibraryComicSortField.fileSize:
      case LibraryComicSortField.pageCount:
        result = a.title.compareTo(b.title);
    }
    return descending ? -result : result;
  }
}
