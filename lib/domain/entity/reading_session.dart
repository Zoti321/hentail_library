import 'package:freezed_annotation/freezed_annotation.dart';

part 'reading_session.freezed.dart';

@freezed
abstract class ReadingSession with _$ReadingSession {
  const factory ReadingSession({
    required String comicId,
    required DateTime date,
    required int durationSeconds,
  }) = _ReadingSession;
}
