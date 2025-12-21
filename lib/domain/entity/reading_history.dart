import 'package:freezed_annotation/freezed_annotation.dart';

part 'reading_history.freezed.dart';

@freezed
abstract class ReadingHistory with _$ReadingHistory {
  factory ReadingHistory({
    required String comicId,
    required String title,
    String? coverUrl,
    required DateTime lastReadTime,
    String? chapterId,
    int? pageIndex,
  }) = _ReadingHistory;
}
