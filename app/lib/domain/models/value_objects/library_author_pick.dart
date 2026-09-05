import 'package:freezed_annotation/freezed_annotation.dart';

part 'library_author_pick.freezed.dart';

/// 筛选 UI 中的「作者」选项。
@freezed
abstract class LibraryAuthorPick with _$LibraryAuthorPick {
  const factory LibraryAuthorPick({required String name}) = _LibraryAuthorPick;
}
