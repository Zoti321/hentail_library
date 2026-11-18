import 'package:hentai_library/features/image_set_library/domain/image_set.dart';

import 'dart:typed_data';

import 'package:hentai_library/features/image_set_library/domain/image_set_image.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_reader_session.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_repository.dart';
import 'package:hentai_library/features/image_set_library/infrastructure/mappers/image_set_frb_mapper.dart';
import 'package:hentai_library/infrastructure/frb/frb_call_guard.dart';
import 'package:hentai_library/src/rust/api/comic.dart' show PageRequestDto;
import 'package:hentai_library/src/rust/api/image_set.dart' as rust;

class ImageSetRepositoryImpl implements ImageSetRepository {
  const ImageSetRepositoryImpl();

  static const int _catalogPageSize = 500;

  @override
  Future<List<ImageSet>> listImageSets(String libraryId) => guardFrb(
    () async =>
        (await rust.listImageSetsFrb(libraryId: libraryId))
            .map(imageSetFromFrb)
            .toList(),
    fallbackMessage: '读取图集失败',
  );

  @override
  Future<List<ImageSet>> listNonEmptyImageSets(String libraryId) =>
      guardFrb(() async {
        const rust.ImageSetFacetFilterDto anyFacet =
            rust.ImageSetFacetFilterDto(any: <String>[], unassigned: false);
        final rust.ImageSetFilterDto filter = rust.ImageSetFilterDto(
          libraryId: libraryId,
          authors: anyFacet,
          tags: anyFacet,
          parodies: anyFacet,
          characters: anyFacet,
          requireImages: true,
        );
        final List<ImageSet> sets = <ImageSet>[];
        for (int page = 1; ; page++) {
          final rust.PagedImageSetCatalogDto dto = await rust
              .fetchImageSetsPageFrb(
                request: PageRequestDto(page: page, pageSize: _catalogPageSize),
                filter: filter,
                sort: const rust.ImageSetSortOptionDto(
                  field: rust.ImageSetSortFieldDto.name,
                  descending: false,
                ),
                grouping: rust.ImageSetGroupingDto.none,
              );
          sets.addAll(dto.items.map((item) => imageSetFromFrb(item.imageSet)));
          if (dto.items.isEmpty || sets.length >= dto.totalCount) {
            return sets;
          }
        }
      }, fallbackMessage: '读取图集失败');

  @override
  Future<List<ImageSetImage>> listImageSetImages(
    String libraryId,
    String imageSetId,
  ) => guardFrb(
    () async => (await rust.listImageSetImagesFrb(
      libraryId: libraryId,
      imageSetId: imageSetId,
    )).map(imageSetImageFromFrb).toList(),
    fallbackMessage: '读取图集图片失败',
  );

  @override
  Future<ImageSetReaderSession> openReaderSession(
    String libraryId,
    String imageSetId,
    int startIndex,
  ) => guardFrb(() async {
    final rust.ImageSetReaderSessionDto dto = await rust.openImageSetReaderFrb(
      libraryId: libraryId,
      imageSetId: imageSetId,
      startIndex: startIndex,
    );
    return ImageSetReaderSession(
      libraryId: dto.libraryId,
      imageSetId: dto.imageSetId,
      pages: dto.pages.map(imageSetImageFromFrb).toList(),
      startIndex: dto.startIndex,
    );
  }, fallbackMessage: '打开图集阅读失败');

  @override
  Future<Uint8List> loadPageBytes(String libraryId, ImageSetImage image) =>
      guardFrb(
        () => rust.loadImageSetPageBytesFrb(
          libraryId: libraryId,
          image: imageSetImageToFrb(image),
        ),
        fallbackMessage: '读取图片失败',
      );
}
