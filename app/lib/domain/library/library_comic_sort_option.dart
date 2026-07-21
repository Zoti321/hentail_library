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
    switch (field) {
      case LibraryComicSortField.title:
        final int result = a.title.compareTo(b.title);
        return descending ? -result : result;
      case LibraryComicSortField.createdAt:
        final int result = a.createdAt.compareTo(b.createdAt);
        return descending ? -result : result;
      case LibraryComicSortField.lastUpdatedAt:
        final int result = a.lastUpdatedAt.compareTo(b.lastUpdatedAt);
        return descending ? -result : result;
      case LibraryComicSortField.publishedAt:
        final int result = _compareOptionalDate(a.publishedAt, b.publishedAt);
        return descending ? -result : result;
      case LibraryComicSortField.readAt:
        return _compareReadAt(a.lastReadTime, b.lastReadTime);
      case LibraryComicSortField.fileSize:
        final int result = a.resourceSize.compareTo(b.resourceSize);
        return descending ? -result : result;
      case LibraryComicSortField.pageCount:
        final int result = a.pageCount.compareTo(b.pageCount);
        return descending ? -result : result;
    }
  }

  /// Nulls always sort last, regardless of [descending].
  int _compareReadAt(DateTime? left, DateTime? right) {
    if (left == null && right == null) {
      return 0;
    }
    if (left == null) {
      return 1;
    }
    if (right == null) {
      return -1;
    }
    final int result = left.compareTo(right);
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
