import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/domain/enums/enums.dart';

part 'category_tag.freezed.dart';

@freezed
abstract class CategoryTag with _$CategoryTag {
  factory CategoryTag({
    required String name,
    @Default(CategoryTagType.tag) CategoryTagType type,
    @Default(false) bool isR18,
  }) = _CategoryTag;
}
