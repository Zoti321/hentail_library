import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/image_set_library/application/load_image_set_catalog_page_use_case.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_catalog_query.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_facets.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_facets_patch.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_image.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_library_gates.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_reader_session.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_repository.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_submission.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/domain/models/value_objects/page_request.dart';

void main() {
  test('forwards library page request and preferences to repository', () async {
    final _FakeRepository repository = _FakeRepository();
    final LoadImageSetCatalogPageUseCase useCase =
        LoadImageSetCatalogPageUseCase(repository);

    final PagedImageSetCatalog page = await useCase(
      libraryId: 'lib',
      request: pageRequest(page: 2, pageSize: 20),
      preferences: const ImageSetBrowsePreferences(
        sort: ImageSetSortOption(field: ImageSetSortField.imageCount),
      ),
    );

    expect(repository.lastLibraryId, 'lib');
    expect(repository.lastRequest, pageRequest(page: 2, pageSize: 20));
    expect(
      repository.lastPreferences?.sort.field,
      ImageSetSortField.imageCount,
    );
    expect(page.items, isEmpty);
    expect(page.totalCount, 0);
  });
}

class _FakeRepository implements ImageSetRepository {
  String? lastLibraryId;
  PageRequest? lastRequest;
  ImageSetBrowsePreferences? lastPreferences;

  @override
  Future<PagedImageSetCatalog> fetchCatalogPage({
    required String libraryId,
    required PageRequest request,
    required ImageSetBrowsePreferences preferences,
  }) async {
    lastLibraryId = libraryId;
    lastRequest = request;
    lastPreferences = preferences;
    return PagedImageSetCatalog(
      items: const <ImageSetCatalogItem>[],
      totalCount: 0,
      page: request.page,
      pageSize: request.pageSize,
    );
  }

  @override
  Future<ImageSetFacets> fetchFacets(String imageSetId) =>
      throw UnimplementedError();

  @override
  Future<void> updateName(String imageSetId, String name) =>
      throw UnimplementedError();

  @override
  Future<void> setNameLocked(String imageSetId, {required bool locked}) =>
      throw UnimplementedError();

  @override
  Future<void> updateFacets(String imageSetId, ImageSetFacetsPatch patch) =>
      throw UnimplementedError();

  @override
  Future<List<ImageSet>> listImageSets(String libraryId) =>
      throw UnimplementedError();

  @override
  Future<List<ImageSet>> listNonEmptyImageSets(String libraryId) =>
      throw UnimplementedError();

  @override
  Future<List<ImageSetImage>> listImageSetImages(
    String libraryId,
    String imageSetId,
  ) => throw UnimplementedError();

  @override
  Future<List<ImageSetImage>> listWorkspaceImages(
    String libraryId,
    String imageSetId,
  ) => throw UnimplementedError();

  @override
  Future<ImageSetReaderSession> openReaderSession(
    String libraryId,
    String imageSetId,
    int startIndex,
  ) => throw UnimplementedError();

  @override
  Future<Uint8List> loadPageBytes(String libraryId, ImageSetImage image) =>
      throw UnimplementedError();

  @override
  Future<Uint8List?> findCover(String imageSetId) => throw UnimplementedError();

  @override
  Future<Uint8List?> ensureCover({
    required String libraryId,
    required String imageSetId,
    required ThumbnailPriority priority,
  }) => throw UnimplementedError();

  @override
  Future<ImageSetLibraryGates> getLibraryGates(String libraryId) =>
      throw UnimplementedError();

  @override
  Future<void> setResourceMutation(
    String libraryId, {
    required bool enabled,
  }) => throw UnimplementedError();

  @override
  Future<void> setManagedLayout(String libraryId, {required bool enabled}) =>
      throw UnimplementedError();

  @override
  Future<void> setImagesExcluded(
    String libraryId,
    String imageSetId,
    List<String> imageIds, {
    required bool excluded,
  }) => throw UnimplementedError();

  @override
  Future<void> reorderImages(
    String libraryId,
    String imageSetId,
    List<String> orderedIds,
  ) => throw UnimplementedError();

  @override
  Future<List<ImageSetSubmission>> listSubmissions(
    String libraryId,
    String imageSetId,
  ) => throw UnimplementedError();

  @override
  Future<ImageSetSubmission> createSubmission(
    String libraryId,
    String imageSetId,
    String name,
  ) => throw UnimplementedError();

  @override
  Future<void> renameSubmission(
    String libraryId,
    String submissionId,
    String name,
  ) => throw UnimplementedError();

  @override
  Future<void> deleteSubmission(String libraryId, String submissionId) =>
      throw UnimplementedError();

  @override
  Future<void> addSubmissionMembers(
    String libraryId,
    String submissionId,
    List<String> imageIds,
  ) => throw UnimplementedError();

  @override
  Future<void> removeSubmissionMembers(
    String libraryId,
    String submissionId,
    List<String> imageIds,
  ) => throw UnimplementedError();

  @override
  Future<void> reorderSubmissionMembers(
    String libraryId,
    String submissionId,
    List<String> orderedIds,
  ) => throw UnimplementedError();

  @override
  Future<List<ImageSetImage>> copyImagesIn(
    String libraryId,
    String imageSetId,
    List<String> sourcePaths,
  ) => throw UnimplementedError();

  @override
  Future<void> deleteImagesOnDisk(
    String libraryId,
    String imageSetId,
    List<String> imageIds,
  ) => throw UnimplementedError();

  @override
  Future<void> takeOverManagedLayout(String libraryId, String imageSetId) =>
      throw UnimplementedError();
}
