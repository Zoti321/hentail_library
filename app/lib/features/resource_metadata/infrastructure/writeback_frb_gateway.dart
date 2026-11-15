import 'package:hentai_library/features/resource_metadata/domain/writeback_gateway.dart';
import 'package:hentai_library/src/rust/api/resource_metadata.dart' as rust;

class WritebackFrbGateway implements WritebackGateway {
  @override
  Future<bool> isEnabled(String libraryId) =>
      rust.getResourceMetadataEnabled(libraryId: libraryId);
  @override
  Future<void> setEnabled(String libraryId, bool enabled) =>
      rust.setResourceMetadataEnabled(libraryId: libraryId, enabled: enabled);
  @override
  Future<bool> processNext() => rust.processResourceMetadataTick();
  @override
  Future<MediaResult> query({
    String? libraryId,
    String? state,
    required bool showR18,
    required int offset,
  }) async {
    final page = await rust.queryMediaResources(
      libraryId: libraryId,
      state: state,
      showR18: showR18,
      offset: offset,
      limit: 50,
    );
    return (
      total: page.total.toInt(),
      items: page.items
          .map((item) {
            final comic = item.comic;
            return (
              comicId: comic.comicId,
              libraryId: comic.libraryId,
              libraryName: item.libraryName,
              path: comic.path,
              title: comic.title,
              format: comic.resourceType,
              state: item.state,
              error: item.error,
              lastSuccessAt: item.lastSuccessAt == null
                  ? null
                  : DateTime.fromMillisecondsSinceEpoch(
                      item.lastSuccessAt!.toInt(),
                    ),
              metadata: <String, String>{
                'title': comic.title,
                'description': comic.description ?? '',
                'authors': comic.authors
                    .map((author) => author.name)
                    .join(', '),
                'tags': comic.tags.join(', '),
                'languages': comic.languages.firstOrNull ?? '',
                'parodies': comic.parodies.join(', '),
                'characters': comic.characters.join(', '),
                'content_rating': comic.contentRating,
                'published_at': comic.publishedAt == null
                    ? ''
                    : DateTime.fromMillisecondsSinceEpoch(
                        comic.publishedAt!.toInt(),
                        isUtc: true,
                      ).toIso8601String(),
              },
            );
          })
          .toList(growable: false),
    );
  }
}
