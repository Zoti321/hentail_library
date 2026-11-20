import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/image_set_library/application/load_image_set_facets_use_case.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_catalog_query.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_facets.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_image.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_library_gates.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_reader_session.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_repository.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_submission.dart';
import 'package:hentai_library/shared/domain/models/value_objects/page_request.dart';

void main() {
  test('forwards image set id to repository fetchFacets', () async {
    final _FakeRepository repository = _FakeRepository();
    final LoadImageSetFacetsUseCase useCase = LoadImageSetFacetsUseCase(
      repository,
    );

    final ImageSetFacets facets = await useCase('set-1');

    expect(repository.lastImageSetId, 'set-1');
    expect(facets.authors, <String>['Alice']);
  });
}

class _FakeRepository implements ImageSetRepository {
  String? lastImageSetId;

  @override
  Future<ImageSetFacets> fetchFacets(String imageSetId) async {
    lastImageSetId = imageSetId;
    return const ImageSetFacets(authors: <String>['Alice']);
  }

  @override
  Future<PagedImageSetCatalog> fetchCatalogPage({
    required String libraryId,
    required PageRequest request,
    required ImageSetBrowsePreferences preferences,
  }) => throw UnimplementedError();

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
