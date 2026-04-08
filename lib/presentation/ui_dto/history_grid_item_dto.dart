import 'package:freezed_annotation/freezed_annotation.dart';

part 'history_grid_item_dto.freezed.dart';

enum HistoryGridItemKind {
  comic,
  series,
}

@freezed
abstract class HistoryGridItemDto with _$HistoryGridItemDto {
  const factory HistoryGridItemDto.comic({
    required String id,
    required String title,
    required DateTime lastReadTime,
    required String coverComicId,
    required String comicId,
    required int? pageIndex,
  }) = ComicHistoryGridItemDto;

  const factory HistoryGridItemDto.series({
    required String id,
    required String title,
    required DateTime lastReadTime,
    required String coverComicId,
    required String seriesName,
    required String lastReadComicId,
    required int? pageIndex,
    required int? lastReadComicOrder,
  }) = SeriesHistoryGridItemDto;
}
