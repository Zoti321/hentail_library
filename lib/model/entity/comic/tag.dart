import 'package:freezed_annotation/freezed_annotation.dart';

part 'tag.freezed.dart';

/// 用户自定义标签（最小建模）。
@freezed
abstract class Tag with _$Tag {
  factory Tag({required String name}) = _Tag;
}

