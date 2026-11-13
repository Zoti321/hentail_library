import 'package:hentai_library/shared/domain/thumbnail/series_cover_source.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hentai_library/features/comic/public/providers/comic_repository_providers.dart';
import 'package:hentai_library/shared/application/contracts/cover_commands.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/presentation/providers/series_slot_providers.dart';

part 'series_cover_providers.g.dart';

final seriesCoverSetCommandProvider = Provider<SeriesCoverSetCommand>((ref) {
  return ({
    required String seriesId,
    required String comicId,
    required String path,
    required ResourceType resourceType,
    required int pageIndex,
  }) async {
    await ref
        .read(comicThumbnailRepoProvider)
        .setSeriesCoverFromPage(
          seriesId: seriesId,
          comicId: comicId,
          path: path,
          resourceType: resourceType,
          pageIndex: pageIndex,
        );
    ref.read(seriesCoverInvalidationSlotProvider)(seriesId);
  };
});

@Riverpod(keepAlive: true)
Future<SeriesCoverSource> seriesCoverSource(Ref ref, String seriesId) {
  return ref.read(comicThumbnailRepoProvider).resolveSeriesCover(seriesId);
}
