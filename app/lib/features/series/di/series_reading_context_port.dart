import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/series/domain/series_repository.dart';
import 'package:hentai_library/shared/di/data_providers.dart';
import 'package:hentai_library/shared/domain/ports/series_reading_context_port.dart';
import 'package:hentai_library/shared/domain/reading/series_reading_context.dart';

final class SeriesReadingContextPortImpl implements SeriesReadingContextPort {
  SeriesReadingContextPortImpl(this._repository);

  final SeriesRepository _repository;

  @override
  Future<SeriesReadingContext?> getReadingContextByComicId(String comicId) =>
      _repository.getReadingContextByComicId(comicId);
}

SeriesReadingContextPort createSeriesReadingContextPort(Ref ref) =>
    SeriesReadingContextPortImpl(ref.read(seriesRepoProvider));
