import 'package:hentai_library/shared/domain/reading/series_reading_context.dart';

/// 按 comicId 解析系列连读上下文（#457；实现 @ series，消费经 shared/di）。
abstract interface class SeriesReadingContextPort {
  Future<SeriesReadingContext?> getReadingContextByComicId(String comicId);
}
