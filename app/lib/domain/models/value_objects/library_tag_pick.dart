import 'package:freezed_annotation/freezed_annotation.dart';

part 'library_tag_pick.freezed.dart';

/// 筛选 UI 中的「标签」选项（无类型分组）。
@freezed
abstract class LibraryTagPick with _$LibraryTagPick {
  const factory LibraryTagPick({required String name}) = _LibraryTagPick;
}
