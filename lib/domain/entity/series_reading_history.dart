import 'package:freezed_annotation/freezed_annotation.dart';

part 'series_reading_history.freezed.dart';

@freezed
abstract class SeriesReadingHistory with _$SeriesReadingHistory {
  factory SeriesReadingHistory({
    required String seriesName,
    required String lastReadComicId,
    required DateTime lastReadTime,
    int? pageIndex,
  }) = _SeriesReadingHistory;
}
