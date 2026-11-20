import 'dart:typed_data';

import 'package:hentai_library/features/image_set_library/domain/image_set.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_image.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_library_gates.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_reader_session.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_repository.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_submission.dart';
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

  @override
  Future<ImageSetLibraryGates> getLibraryGates(String libraryId) => guardFrb(
    () async => imageSetLibraryGatesFromFrb(
      await rust.getImageSetLibraryGatesFrb(libraryId: libraryId),
    ),
    fallbackMessage: '读取图集库门闩失败',
  );

  @override
  Future<void> setResourceMutation(
    String libraryId, {
    required bool enabled,
  }) => guardFrb(
    () => rust.setImageSetResourceMutationFrb(
      libraryId: libraryId,
      enabled: enabled,
    ),
    fallbackMessage: '设置图集资源变更失败',
  );

  @override
  Future<void> setManagedLayout(String libraryId, {required bool enabled}) =>
      guardFrb(
        () => rust.setImageSetManagedLayoutFrb(
          libraryId: libraryId,
          enabled: enabled,
        ),
        fallbackMessage: '设置图集托管布局失败',
      );

  @override
  Future<void> setImagesExcluded(
    String libraryId,
    String imageSetId,
    List<String> imageIds, {
    required bool excluded,
  }) => guardFrb(
    () => rust.setImageSetImagesExcludedFrb(
      libraryId: libraryId,
      imageSetId: imageSetId,
      imageIds: imageIds,
      excluded: excluded,
    ),
    fallbackMessage: '更新图集排除状态失败',
  );

  @override
  Future<void> reorderImages(
    String libraryId,
    String imageSetId,
    List<String> orderedIds,
  ) => guardFrb(
    () => rust.reorderImageSetImagesFrb(
      libraryId: libraryId,
      imageSetId: imageSetId,
      orderedIds: orderedIds,
    ),
    fallbackMessage: '重排图集图片失败',
  );

  @override
  Future<List<ImageSetSubmission>> listSubmissions(
    String libraryId,
    String imageSetId,
  ) => guardFrb(
    () async => (await rust.listImageSetSubmissionsFrb(
      libraryId: libraryId,
      imageSetId: imageSetId,
    )).map(imageSetSubmissionFromFrb).toList(),
    fallbackMessage: '读取图集投稿失败',
  );

  @override
  Future<ImageSetSubmission> createSubmission(
    String libraryId,
    String imageSetId,
    String name,
  ) => guardFrb(
    () async => imageSetSubmissionFromFrb(
      await rust.createImageSetSubmissionFrb(
        libraryId: libraryId,
        imageSetId: imageSetId,
        name: name,
      ),
    ),
    fallbackMessage: '创建图集投稿失败',
  );

  @override
  Future<void> renameSubmission(
    String libraryId,
    String submissionId,
    String name,
  ) => guardFrb(
    () => rust.renameImageSetSubmissionFrb(
      libraryId: libraryId,
      submissionId: submissionId,
      name: name,
    ),
    fallbackMessage: '重命名图集投稿失败',
  );

  @override
  Future<void> deleteSubmission(String libraryId, String submissionId) =>
      guardFrb(
        () => rust.deleteImageSetSubmissionFrb(
          libraryId: libraryId,
          submissionId: submissionId,
        ),
        fallbackMessage: '删除图集投稿失败',
      );

  @override
  Future<void> addSubmissionMembers(
    String libraryId,
    String submissionId,
    List<String> imageIds,
  ) => guardFrb(
    () => rust.addImageSetSubmissionMembersFrb(
      libraryId: libraryId,
      submissionId: submissionId,
      imageIds: imageIds,
    ),
    fallbackMessage: '添加投稿成员失败',
  );

  @override
  Future<void> removeSubmissionMembers(
    String libraryId,
    String submissionId,
    List<String> imageIds,
  ) => guardFrb(
    () => rust.removeImageSetSubmissionMembersFrb(
      libraryId: libraryId,
      submissionId: submissionId,
      imageIds: imageIds,
    ),
    fallbackMessage: '移除投稿成员失败',
  );

  @override
  Future<void> reorderSubmissionMembers(
    String libraryId,
    String submissionId,
    List<String> orderedIds,
  ) => guardFrb(
    () => rust.reorderImageSetSubmissionMembersFrb(
      libraryId: libraryId,
      submissionId: submissionId,
      orderedIds: orderedIds,
    ),
    fallbackMessage: '重排投稿成员失败',
  );

  @override
  Future<List<ImageSetImage>> copyImagesIn(
    String libraryId,
    String imageSetId,
    List<String> sourcePaths,
  ) => guardFrb(
    () async => (await rust.copyImagesIntoImageSetFrb(
      libraryId: libraryId,
      imageSetId: imageSetId,
      sourcePaths: sourcePaths,
    )).map(imageSetImageFromFrb).toList(),
    fallbackMessage: '复制图片到图集失败',
  );

  @override
  Future<void> deleteImagesOnDisk(
    String libraryId,
    String imageSetId,
    List<String> imageIds,
  ) => guardFrb(
    () => rust.deleteImageSetImagesOnDiskFrb(
      libraryId: libraryId,
      imageSetId: imageSetId,
      imageIds: imageIds,
    ),
    fallbackMessage: '删除图集磁盘图片失败',
  );

  @override
  Future<void> takeOverManagedLayout(String libraryId, String imageSetId) =>
      guardFrb(
        () => rust.takeOverImageSetManagedLayoutFrb(
          libraryId: libraryId,
          imageSetId: imageSetId,
        ),
        fallbackMessage: '托管布局接管失败',
      );
}
