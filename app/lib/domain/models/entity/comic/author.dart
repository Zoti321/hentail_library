import 'package:freezed_annotation/freezed_annotation.dart';

part 'author.freezed.dart';

/// Author 稳定身份：可变显示名 + 可选认证态。
@freezed
abstract class Author with _$Author {
  factory Author({
    int? id,
    required String name,
    @Default(false) bool verified,
  }) = _Author;
}
