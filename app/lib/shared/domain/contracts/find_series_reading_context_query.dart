import 'package:hentai_library/shared/domain/reading/series_reading_context.dart';

typedef FindSeriesReadingContextQuery = Future<SeriesReadingContext?> Function(
  String comicId,
);
