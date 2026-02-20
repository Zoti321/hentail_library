import 'package:freezed_annotation/freezed_annotation.dart';

part 'series_item.freezed.dart';

@freezed
abstract class SeriesItem with _$SeriesItem {
  factory SeriesItem({
    required String comicId,
    required int order,
  }) = _SeriesItem;
}

