import 'package:hentai_library/data/mappers/comic/comic_mapper.dart';
import 'package:hentai_library/data/mappers/database/comic_db_mapper.dart';
import 'package:hentai_library/data/mappers/database/reading_history_db_mapper.dart';
import 'package:hentai_library/data/mappers/database/series_db_mapper.dart';
import 'package:hentai_library/data/mappers/database/series_reading_history_db_mapper.dart';

abstract interface class MappingModule {
  ComicMapper get comic;
  ComicDbMapper get comicDb;
  ReadingHistoryDbMapper get readingHistoryDb;
  SeriesDbMapper get seriesDb;
  SeriesReadingHistoryDbMapper get seriesReadingHistoryDb;
}

class DefaultMappingModule implements MappingModule {
  const DefaultMappingModule();

  @override
  ComicMapper get comic => const ComicMapper();

  @override
  ComicDbMapper get comicDb => const ComicDbMapper();

  @override
  ReadingHistoryDbMapper get readingHistoryDb => const ReadingHistoryDbMapper();

  @override
  SeriesDbMapper get seriesDb => const SeriesDbMapper();

  @override
  SeriesReadingHistoryDbMapper get seriesReadingHistoryDb =>
      const SeriesReadingHistoryDbMapper();
}

