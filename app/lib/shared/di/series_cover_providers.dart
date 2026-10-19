import 'package:hentai_library/shared/domain/thumbnail/series_cover_source.dart';
import 'package:hentai_library/shared/di/data_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'series_cover_providers.g.dart';

@Riverpod(keepAlive: true)
Future<SeriesCoverSource> seriesCoverSource(Ref ref, String seriesId) {
  return ref.read(comicThumbnailRepoProvider).resolveSeriesCover(seriesId);
}
