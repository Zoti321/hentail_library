import 'package:freezed_annotation/freezed_annotation.dart';

part 'chapter.freezed.dart';

@freezed
abstract class Chapter with _$Chapter {
  factory Chapter({
    required String id, // 业务唯一id
    int? number, //话号(第几话)
    String? title,
    String? summary,
    required String imageDir,
    DateTime? publishedAt,
    @Default(0) int pageCount,
    int? viewCount,
  }) = _Chapter;

  Chapter._();
}
