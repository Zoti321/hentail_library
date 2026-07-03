import 'package:freezed_annotation/freezed_annotation.dart';

part 'history_grid_item_dto.freezed.dart';

@freezed
abstract class HistoryGridItemDto with _$HistoryGridItemDto {
  const factory HistoryGridItemDto({
    required String id,
    required String title,
    required DateTime lastReadTime,
    required String coverComicId,
    required String comicId,
    required int? pageIndex,
  }) = _HistoryGridItemDto;
}
