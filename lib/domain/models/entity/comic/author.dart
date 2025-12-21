import 'package:freezed_annotation/freezed_annotation.dart';

part 'author.freezed.dart';

/// 作者（最小建模，与 [Tag] 对称）。
@freezed
abstract class Author with _$Author {
  factory Author({required String name}) = _Author;
}
