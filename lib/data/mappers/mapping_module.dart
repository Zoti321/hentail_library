import 'package:hentai_library/data/mappers/comic/comic_mapper.dart';
import 'package:hentai_library/data/mappers/database/reading_history_db_mapper.dart';
import 'package:hentai_library/data/mappers/database/series_reading_history_db_mapper.dart';

abstract interface class MappingModule {
  ComicMapper get comic;
  ReadingHistoryDbMapper get readingHistoryDb;
  SeriesReadingHistoryDbMapper get seriesReadingHistoryDb;
}

class DefaultMappingModule implements MappingModule {
  const DefaultMappingModule();

  @override
  ComicMapper get comic => const ComicMapper();

  @override
  ReadingHistoryDbMapper get readingHistoryDb => const ReadingHistoryDbMapper();

  @override
  SeriesReadingHistoryDbMapper get seriesReadingHistoryDb =>
      const SeriesReadingHistoryDbMapper();
}

