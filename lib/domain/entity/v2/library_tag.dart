import 'package:freezed_annotation/freezed_annotation.dart';

part 'library_tag.freezed.dart';

/// 用户自定义标签（最小建模）。
@freezed
abstract class LibraryTag with _$LibraryTag {
  factory LibraryTag({required String name}) = _LibraryTag;
}
